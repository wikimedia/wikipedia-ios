-- =====================================================================================
-- iOS Home Feed A/B (ios-home-feed): New Install group imbalance checks
-- Engine: Presto/Trino (Superset SQL Lab). Run each query separately.
--
-- ASSUMPTIONS (verify before trusting results):
--   * Test Kitchen events land in event.product_metrics_app_base
--     (app stream "product_metrics.app_base", schema /analytics/product_metrics/app/base/2.0.0).
--   * agent.app_install_id, agent.app_version_name, agent.release_status are populated
--     (they are only sent if the stream config requests them via provide_values).
--
-- DATES: find/replace these literals before running.
--   '2026-09-01'  -> analysis window start (inclusive)
--   '2026-09-25'  -> analysis window end   (exclusive)
--   '2026-07-01'  -> lookback start used to decide "new" (must be well before the window,
--                    ideally before the experiment shipped)
--   Also adjust the coarse partition filter (year/month) in each query to cover those dates.
--
-- EVENT REFERENCE (from app code):
--   Exposure (both groups, every launch, before onboarding):
--     instrument_name='apps-home-feed', action='experiment_exposure', experiment.enrolled='ios-home-feed'
--   New-install signals, CONTROL ONLY (legacy onboarding, WMFWelcomeInitialViewController):
--     instrument_name='apps-open',       action='app_open',   action_source='new_install_onboarding_start'  (no experiment data)
--     instrument_name='apps-onboarding', action='impression', action_source='onboarding_welcome_legacy'     (has experiment data)
--   TREATMENT-ONLY events (new onboarding, AppOnboardingCoordinator):
--     instrument_name='apps-onboarding', action_source IN ('onboarding_welcome','onboarding_privacy','onboarding_language')
--     instrument_name='apps-home-feed',  action_source IN ('feed_entry','feed_loading')
-- =====================================================================================


-- -------------------------------------------------------------------------------------
-- Q1. What do the new-install signals look like, split by the group on the event itself?
--     Expectation from code: new_install_onboarding_start has NO group; onboarding_welcome_legacy
--     is ~100% control; onboarding_welcome is ~100% treatment. Control legacy vs treatment
--     onboarding_welcome counts should be roughly equal if assignment is 50/50.
-- -------------------------------------------------------------------------------------
SELECT
    CASE
        WHEN instrument_name = 'apps-open' AND action_source = 'new_install_onboarding_start' THEN '1 app_open new_install_onboarding_start'
        WHEN action_source = 'onboarding_welcome_legacy' THEN '2 onboarding_welcome_legacy (control flow)'
        WHEN action_source = 'onboarding_welcome'        THEN '3 onboarding_welcome (treatment flow)'
    END AS signal,
    COALESCE(experiment.assigned, '(none)') AS assigned_on_event,
    COUNT(DISTINCT agent.app_install_id) AS installs,
    COUNT(*) AS events
FROM event.product_metrics_app_base
WHERE year = 2026 AND month = 9
  AND from_iso8601_timestamp(dt) >= TIMESTAMP '2026-09-01 00:00:00 UTC'
  AND from_iso8601_timestamp(dt) <  TIMESTAMP '2026-09-25 00:00:00 UTC'
  AND agent.client_platform = 'ios'
  AND agent.release_status = 'prod'
  AND (
        (instrument_name = 'apps-open' AND action = 'app_open' AND action_source = 'new_install_onboarding_start')
     OR (instrument_name = 'apps-onboarding' AND action = 'impression'
         AND action_source IN ('onboarding_welcome_legacy', 'onboarding_welcome'))
  )
GROUP BY 1, 2
ORDER BY 1, 2;


-- -------------------------------------------------------------------------------------
-- Q2. Assignment balance independent of onboarding: first experiment_exposure per install.
--     "new" = the install's first event of ANY kind (since lookback start) falls in the window.
--     If this is ~50/50 for new installs, randomization is fine and the imbalance is measurement.
--     n_groups_seen > 1 means the install switched groups (re-randomization).
-- -------------------------------------------------------------------------------------
WITH first_seen AS (
    SELECT agent.app_install_id AS install_id,
           MIN(from_iso8601_timestamp(dt)) AS first_event_ts
    FROM event.product_metrics_app_base
    WHERE year = 2026 AND month BETWEEN 7 AND 9
      AND from_iso8601_timestamp(dt) >= TIMESTAMP '2026-07-01 00:00:00 UTC'
      AND from_iso8601_timestamp(dt) <  TIMESTAMP '2026-09-25 00:00:00 UTC'
      AND agent.client_platform = 'ios'
      AND agent.release_status = 'prod'
      AND agent.app_install_id IS NOT NULL
    GROUP BY 1
),
exposures AS (
    SELECT agent.app_install_id AS install_id,
           MIN_BY(experiment.assigned, from_iso8601_timestamp(dt)) AS first_assigned,
           COUNT(DISTINCT experiment.assigned) AS n_groups_seen
    FROM event.product_metrics_app_base
    WHERE year = 2026 AND month = 9
      AND from_iso8601_timestamp(dt) >= TIMESTAMP '2026-09-01 00:00:00 UTC'
      AND from_iso8601_timestamp(dt) <  TIMESTAMP '2026-09-25 00:00:00 UTC'
      AND agent.client_platform = 'ios'
      AND agent.release_status = 'prod'
      AND instrument_name = 'apps-home-feed'
      AND action = 'experiment_exposure'
      AND experiment.enrolled = 'ios-home-feed'
    GROUP BY 1
)
SELECT
    CASE WHEN f.first_event_ts >= TIMESTAMP '2026-09-01 00:00:00 UTC' THEN 'new' ELSE 'existing' END AS install_type,
    e.first_assigned,
    COUNT(*) AS installs,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY
        CASE WHEN f.first_event_ts >= TIMESTAMP '2026-09-01 00:00:00 UTC' THEN 'new' ELSE 'existing' END), 2) AS pct_of_type,
    SUM(CASE WHEN e.n_groups_seen > 1 THEN 1 ELSE 0 END) AS installs_that_switched_groups
FROM exposures e
JOIN first_seen f ON f.install_id = e.install_id
GROUP BY 1, 2
ORDER BY 1, 2;


-- -------------------------------------------------------------------------------------
-- Q3. Installs that switched groups (re-randomization). Lists the timeline per install.
--     Any rows here = bucket was lost/re-drawn (failed read or deleted bucket file).
--     Look at app_version_name around the switch: an update can trigger it.
-- -------------------------------------------------------------------------------------
WITH exp AS (
    SELECT agent.app_install_id AS install_id,
           experiment.assigned AS assigned,
           agent.app_version_name AS app_version_name,
           from_iso8601_timestamp(dt) AS ts
    FROM event.product_metrics_app_base
    WHERE year = 2026 AND month = 9
      AND from_iso8601_timestamp(dt) >= TIMESTAMP '2026-09-01 00:00:00 UTC'
      AND from_iso8601_timestamp(dt) <  TIMESTAMP '2026-09-25 00:00:00 UTC'
      AND agent.client_platform = 'ios'
      AND agent.release_status = 'prod'
      AND instrument_name = 'apps-home-feed'
      AND action = 'experiment_exposure'
      AND experiment.enrolled = 'ios-home-feed'
),
switchers AS (
    SELECT install_id FROM exp GROUP BY 1 HAVING COUNT(DISTINCT assigned) > 1
)
SELECT
    COUNT(DISTINCT install_id) AS switching_installs,
    SUM(CASE WHEN first_assigned = 'control'   AND last_assigned = 'treatment' THEN 1 ELSE 0 END) AS control_to_treatment,
    SUM(CASE WHEN first_assigned = 'treatment' AND last_assigned = 'control'   THEN 1 ELSE 0 END) AS treatment_to_control
FROM (
    SELECT install_id,
           MIN_BY(assigned, ts) AS first_assigned,
           MAX_BY(assigned, ts) AS last_assigned
    FROM exp
    WHERE install_id IN (SELECT install_id FROM switchers)
    GROUP BY 1
) t;


-- -------------------------------------------------------------------------------------
-- Q4. Mislabelled events: treatment-only screens logged as control, or the control-only
--     legacy screen logged as treatment. Any rows = the ".control" default fallback fired,
--     or the group changed between assignment and logging.
-- -------------------------------------------------------------------------------------
SELECT
    instrument_name,
    action,
    action_source,
    experiment.assigned AS assigned_on_event,
    agent.app_version_name AS app_version_name,
    COUNT(DISTINCT agent.app_install_id) AS installs,
    COUNT(*) AS events
FROM event.product_metrics_app_base
WHERE year = 2026 AND month = 9
  AND from_iso8601_timestamp(dt) >= TIMESTAMP '2026-09-01 00:00:00 UTC'
  AND from_iso8601_timestamp(dt) <  TIMESTAMP '2026-09-25 00:00:00 UTC'
  AND agent.client_platform = 'ios'
  AND agent.release_status = 'prod'
  AND experiment.enrolled = 'ios-home-feed'
  AND (
        -- treatment-only screens logged as control
        (experiment.assigned = 'control' AND (
             (instrument_name = 'apps-onboarding' AND action_source IN ('onboarding_welcome', 'onboarding_privacy', 'onboarding_language'))
          OR (instrument_name = 'apps-home-feed'  AND action_source IN ('feed_entry', 'feed_loading'))
        ))
        -- control-only screen logged as treatment
     OR (experiment.assigned = 'treatment' AND action_source = 'onboarding_welcome_legacy')
  )
GROUP BY 1, 2, 3, 4, 5
ORDER BY events DESC;


-- -------------------------------------------------------------------------------------
-- Q5. For installs that sent the (control-only) new_install_onboarding_start event:
--     which group does experiment_exposure say they are in, and on what app version?
--     Treatment rows here are the ones to explain: expect them to be group switchers or
--     installs that started on a build without the experiment and then upgraded.
-- -------------------------------------------------------------------------------------
WITH new_install AS (
    SELECT agent.app_install_id AS install_id,
           MIN(from_iso8601_timestamp(dt)) AS install_ts,
           MIN_BY(agent.app_version_name, from_iso8601_timestamp(dt)) AS install_version
    FROM event.product_metrics_app_base
    WHERE year = 2026 AND month = 9
      AND from_iso8601_timestamp(dt) >= TIMESTAMP '2026-09-01 00:00:00 UTC'
      AND from_iso8601_timestamp(dt) <  TIMESTAMP '2026-09-25 00:00:00 UTC'
      AND agent.client_platform = 'ios'
      AND agent.release_status = 'prod'
      AND instrument_name = 'apps-open'
      AND action = 'app_open'
      AND action_source = 'new_install_onboarding_start'
    GROUP BY 1
),
exposure AS (
    SELECT agent.app_install_id AS install_id,
           MIN_BY(experiment.assigned, from_iso8601_timestamp(dt)) AS first_assigned,
           MAX_BY(experiment.assigned, from_iso8601_timestamp(dt)) AS last_assigned,
           MIN(from_iso8601_timestamp(dt)) AS first_exposure_ts
    FROM event.product_metrics_app_base
    WHERE year = 2026 AND month = 9
      AND from_iso8601_timestamp(dt) >= TIMESTAMP '2026-09-01 00:00:00 UTC'
      AND from_iso8601_timestamp(dt) <  TIMESTAMP '2026-09-25 00:00:00 UTC'
      AND agent.client_platform = 'ios'
      AND agent.release_status = 'prod'
      AND instrument_name = 'apps-home-feed'
      AND action = 'experiment_exposure'
      AND experiment.enrolled = 'ios-home-feed'
    GROUP BY 1
)
SELECT
    n.install_version,
    COALESCE(e.first_assigned, '(no exposure)') AS first_assigned,
    COALESCE(e.last_assigned,  '(no exposure)') AS last_assigned,
    CASE WHEN e.first_exposure_ts IS NULL THEN 'none'
         WHEN e.first_exposure_ts <= n.install_ts THEN 'exposure before install event'
         ELSE 'exposure after install event' END AS exposure_timing,
    COUNT(*) AS installs
FROM new_install n
LEFT JOIN exposure e ON e.install_id = n.install_id
GROUP BY 1, 2, 3, 4
ORDER BY installs DESC;


-- -------------------------------------------------------------------------------------
-- Q6. Daily split of NEW assignments (first exposure per install), by app version.
--     A day or version where the split drifts from 50/50 points at a specific release.
-- -------------------------------------------------------------------------------------
WITH first_exposure AS (
    SELECT agent.app_install_id AS install_id,
           MIN(from_iso8601_timestamp(dt)) AS ts,
           MIN_BY(experiment.assigned, from_iso8601_timestamp(dt)) AS assigned,
           MIN_BY(agent.app_version_name, from_iso8601_timestamp(dt)) AS app_version_name
    FROM event.product_metrics_app_base
    WHERE year = 2026 AND month BETWEEN 7 AND 9
      AND from_iso8601_timestamp(dt) >= TIMESTAMP '2026-07-01 00:00:00 UTC'
      AND from_iso8601_timestamp(dt) <  TIMESTAMP '2026-09-25 00:00:00 UTC'
      AND agent.client_platform = 'ios'
      AND agent.release_status = 'prod'
      AND instrument_name = 'apps-home-feed'
      AND action = 'experiment_exposure'
      AND experiment.enrolled = 'ios-home-feed'
    GROUP BY 1
)
SELECT
    DATE(ts) AS first_exposure_date,
    app_version_name,
    SUM(CASE WHEN assigned = 'control'   THEN 1 ELSE 0 END) AS control,
    SUM(CASE WHEN assigned = 'treatment' THEN 1 ELSE 0 END) AS treatment,
    ROUND(100.0 * SUM(CASE WHEN assigned = 'treatment' THEN 1 ELSE 0 END) / COUNT(*), 2) AS pct_treatment
FROM first_exposure
WHERE ts >= TIMESTAMP '2026-09-01 00:00:00 UTC'
GROUP BY 1, 2
ORDER BY 1, 2;
