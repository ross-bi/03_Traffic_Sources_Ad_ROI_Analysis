SELECT
  table_name,
  ordinal_position,
  column_name,
  data_type,
  is_nullable
FROM `ross-bi-project-03.traffic_ad_roi_clean.INFORMATION_SCHEMA.COLUMNS`
ORDER BY table_name, ordinal_position;
