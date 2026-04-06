from __future__ import annotations

import shutil
from datetime import datetime
from time import perf_counter, sleep

from tracing_constants import LOG_EVENT_TIMESTAMP_PATTERN
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
    """Proceed only when the latest two complete log events are non-idle followed by idle."""

    if len(events) < 2:
        return False

    previous_event = events[-2].rstrip()
    last_event = events[-1].rstrip()
    return not previous_event.endswith(idle_message) and last_event.endswith(idle_message)



def wait_for_post_processing_idle(
    container_prefix: str,
    idle_message: str,
    since_utc: str,
    timeout_seconds: int,
    initial_wait_seconds: int,
) -> None:
    """Pause capture until the post-processing container reports its queue is drained."""

    docker_executable = shutil.which("docker")
    if not docker_executable:
        print("docker executable not found; skipping post-processing log wait")
        return

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
