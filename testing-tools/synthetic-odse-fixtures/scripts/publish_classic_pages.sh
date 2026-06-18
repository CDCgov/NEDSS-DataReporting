#!/usr/bin/env bash
# publish_classic_pages.sh — republish all NBS6 page-builder pages into the
# classic-NBS runtime metadata, so investigation DETAIL pages render in the
# wildfly UI (localhost:7003/nbs).
#
# WHY: the synthetic fixtures author investigations directly in NBS_ODSE. The
# classic investigation detail page resolves its form from the published page
# metadata (condition -> page_cond_mapping -> published WA_template). On a fresh
# stack those pages are not all in "published" mode, so opening an investigation
# throws `NullPointerException: ... Null object to DSInvestigationFormCd` and you
# get an Error page. Running NBS6's PublishAllPages batch fixes this (it took the
# detail views from 0/31 to 22/31 rendering; a handful of condition pages -
# COVID/Pertussis/Malaria/Strep - still fail, a separate page-specific issue).
#
# This is a CLASSIC-UI setup step, independent of the RDB_MODERN pipeline. Run it
# once after the stack is up (it's idempotent - it just republishes).
#
# Usage: ./scripts/publish_classic_pages.sh [wildfly_container] [user]
set -euo pipefail

CONTAINER="${1:-nedss-datareporting-wildfly-1}"
USER_ID="${2:-superuser}"

echo "[publish] republishing all NBS6 pages as '$USER_ID' in $CONTAINER ..."
echo Y | docker exec -i "$CONTAINER" bash -lc \
  "cd /opt/jboss/wildfly/nedssdomain/Nedss/BatchFiles && echo Y | ./PublishAllPages.sh '$USER_ID'" \
  | tail -5
echo "[publish] done. Open an investigation in the UI to confirm the detail page renders."
