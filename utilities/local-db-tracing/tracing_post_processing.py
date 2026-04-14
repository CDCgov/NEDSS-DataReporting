from __future__ import annotations

import shutil
from datetime import datetime
from time import perf_counter, sleep

from tracing_constants import (
    DEFAULT_KAFKA_CONSUMER_GROUPS,
    DEFAULT_KAFKA_CONTAINER_PREFIX,
    LOG_EVENT_TIMESTAMP_PATTERN,
)
from tracing_sql import run_process


def progress_now() -> str:
    """Render local timestamps for user-facing progress messages during long-running trace phases."""

    return datetime.now().astimezone().replace(microsecond=0).isoformat()



def log_progress(action: str) -> None:
    """Emit timestamped progress so long CDC phases can be correlated with the current bottleneck."""

    print(f"[{progress_now()}] {action}")



def find_container_name_by_prefix(docker_executable: str, prefix: str) -> tuple[str | None, str]:
    """Resolve the post-processing container dynamically because Compose appends numeric suffixes."""

    result = run_process([docker_executable, "ps", "--format", "{{.Names}}"])
    if result.returncode != 0:
        detail = (result.stderr or result.stdout or "docker ps failed").strip()
        return None, detail

    names = [line.strip() for line in result.stdout.splitlines() if line.strip()]
    matches = sorted(name for name in names if name.startswith(prefix))
    if not matches:
        return None, f"No running container name starts with {prefix}"
    if len(matches) > 1:
        return matches[0], f"Multiple containers matched; using {matches[0]}"
    return matches[0], ""




def parse_consumer_group_lags(output: str) -> list[int]:
    """Extract numeric lag values from kafka-consumer-groups describe output rows."""

    lags: list[int] = []
    for raw_line in output.splitlines():
        line = raw_line.strip()
        if not line or line.startswith("GROUP"):
            continue

        parts = line.split()
        if len(parts) < 6:
            continue

        lag_value = parts[5]
        if lag_value == "-":
            lags.append(0)
            continue

        try:
            lags.append(int(lag_value))
        except ValueError:
            continue
    return lags



def fetch_consumer_group_lag(
    docker_executable: str,
    kafka_container_name: str,
    group_id: str,
) -> tuple[bool, list[int], str]:
    """Return parsed lag values for a consumer group via the Kafka CLI in the broker container."""

    result = run_process(
        [
            docker_executable,
            "exec",
            kafka_container_name,
            "kafka-consumer-groups",
            "--bootstrap-server",
            "kafka:29092",
            "--describe",
            "--group",
            group_id,
            "--timeout",
            "10000",
        ]
    )
    combined_output = "\n".join(part for part in (result.stdout, result.stderr) if part).strip()

    if result.returncode != 0:
        detail = combined_output or "kafka-consumer-groups failed"
        lowered = detail.lower()
        if "does not exist" in lowered or "no committed offsets" in lowered:
            return True, [], detail
        return False, [], detail

    return True, parse_consumer_group_lags(combined_output), combined_output



def all_consumer_groups_at_zero_lag(
    docker_executable: str,
    kafka_container_name: str,
    group_ids: tuple[str, ...],
) -> tuple[bool, bool, dict[str, int], str | None]:
    """Check whether every configured consumer group has zero lag across all partitions."""

    group_totals: dict[str, int] = {}
    for group_id in group_ids:
        success, lags, detail = fetch_consumer_group_lag(docker_executable, kafka_container_name, group_id)
        if not success:
            return False, False, {}, f"{group_id}: {detail}"
        group_totals[group_id] = sum(lags)

    is_zero = all(total == 0 for total in group_totals.values())
    return True, is_zero, group_totals, None



def wait_for_kafka_lag_zero(
    docker_executable: str,
    kafka_container_prefix: str,
    group_ids: tuple[str, ...],
    timeout_seconds: int,
) -> None:
    """Wait until all monitored Kafka consumer groups report zero lag."""

    kafka_container_name, detail = find_container_name_by_prefix(docker_executable, kafka_container_prefix)
    if kafka_container_name is None:
        print(f"Skipping Kafka lag wait: {detail}")
        return

    if detail:
        print(detail)

    log_progress(
        f"Waiting up to {timeout_seconds}s for Kafka lag to reach zero in groups: {', '.join(group_ids)}"
    )
    deadline = perf_counter() + max(timeout_seconds, 0)
    print(f"[{progress_now()}] Waiting for Kafka consumer lag in {kafka_container_name}: ", end="", flush=True)
    while perf_counter() <= deadline:
        success, at_zero, group_totals, error = all_consumer_groups_at_zero_lag(
            docker_executable,
            kafka_container_name,
            group_ids,
        )
        if not success:
            print()
            print(f"Skipping Kafka lag wait: {error}")
            return

        if at_zero:
            print()
            log_progress(f"Observed zero Kafka lag across groups: {', '.join(group_ids)}")
            return

        print(".", end="", flush=True)
        sleep(2)

    print()
    lag_summary = ", ".join(f"{group_id}={lag}" for group_id, lag in group_totals.items())
    print(
        f"Timed out after {timeout_seconds}s waiting for Kafka lag to reach zero ({lag_summary}); continuing log wait"
    )



def fetch_container_logs_since(docker_executable: str, container_name: str, since_utc: str) -> tuple[bool, str]:
    """Read recent container logs from the action window without tailing indefinitely."""

    result = run_process([docker_executable, "logs", "--since", since_utc, container_name])
    if result.returncode != 0:
        detail = (result.stderr or result.stdout or "docker logs failed").strip()
        return False, detail
    return True, "\n".join(part for part in (result.stdout, result.stderr) if part)



def extract_meaningful_log_events(output: str) -> list[str]:
    """Group multiline docker log output into complete timestamped events for tail-based idle detection."""

    events: list[str] = []
    current_event_lines: list[str] = []
    for raw_line in output.splitlines():
        line = raw_line.rstrip()
        if not line.strip():
            continue

        if LOG_EVENT_TIMESTAMP_PATTERN.match(line):
            if current_event_lines:
                events.append("\n".join(current_event_lines))
            current_event_lines = [line]
            continue

        if current_event_lines:
            current_event_lines.append(line)
        else:
            current_event_lines = [line]

    if current_event_lines:
        events.append("\n".join(current_event_lines))
    return events



def has_post_processing_idle_tail(events: list[str], idle_message: str) -> bool:
    """Proceed when latest event is idle and no pending datamart event appears after the idle boundary."""

    if len(events) < 2:
        return False

    def is_datamart_event(event: str) -> bool:
        lowered = event.lower()
        return "processdatamartdata" in lowered and "datamart" in lowered and "stored proc" in lowered

    last_datamart_index = -1
    for index, event in enumerate(events):
        if is_datamart_event(event):
            last_datamart_index = index

    last_event = events[-1].rstrip()
    if not last_event.endswith(idle_message):
        return False

    # The final idle line is only meaningful if it is newer than any datamart stored-proc activity.
    return len(events) - 1 > last_datamart_index



def wait_for_post_processing_idle(
    container_prefix: str,
    idle_message: str,
    since_utc: str,
    timeout_seconds: int,
    initial_wait_seconds: int,
    kafka_container_prefix: str = DEFAULT_KAFKA_CONTAINER_PREFIX,
    kafka_consumer_groups: tuple[str, ...] = DEFAULT_KAFKA_CONSUMER_GROUPS,
) -> None:
    """Pause capture until the post-processing container reports its queue is drained."""

    docker_executable = shutil.which("docker")
    if not docker_executable:
        print("docker executable not found; skipping post-processing log wait")
        return

    wait_for_kafka_lag_zero(
        docker_executable,
        kafka_container_prefix,
        kafka_consumer_groups,
        timeout_seconds,
    )

    container_name, detail = find_container_name_by_prefix(docker_executable, container_prefix)
    if container_name is None:
        print(f"Skipping post-processing log wait: {detail}")
        return

    if detail:
        print(detail)

    log_progress(f"Waiting up to {timeout_seconds}s for {container_name} to log: {idle_message}")
    if initial_wait_seconds > 0:
        log_progress(f"Sleeping {initial_wait_seconds}s before polling logs")
        sleep(initial_wait_seconds)

    deadline = perf_counter() + max(timeout_seconds, 0)
    print(f"[{progress_now()}] Waiting for {container_name}: ", end="", flush=True)
    while perf_counter() <= deadline:
        success, output = fetch_container_logs_since(docker_executable, container_name, since_utc)
        if not success:
            print()
            print(f"Skipping post-processing log wait: {output}")
            return
        events = extract_meaningful_log_events(output)
        if has_post_processing_idle_tail(events, idle_message):
            print()
            log_progress(f"Observed idle message in {container_name}")
            return
        print(".", end="", flush=True)
        sleep(2)

    print()
    print(
        f"Timed out after {timeout_seconds}s waiting for {container_name} to log the idle message; continuing capture"
    )
