-- Ensure next month partition for scrapped_ads exists, with child indexes attached
-- Run this periodically (e.g., daily via cron) to prepare the partition ahead of time.

DO $$
DECLARE
  nxt_month date := (date_trunc('month', now()) + interval '1 month')::date;
  part_name text := format('scrapped_ads_y%sm%s', to_char(nxt_month, 'YYYY'), to_char(nxt_month, 'MM'));
BEGIN
  -- Create next-month partition
  EXECUTE format($f$
    CREATE TABLE IF NOT EXISTS %I PARTITION OF scrapped_ads
    FOR VALUES FROM (%L) TO (%L)
  $f$, part_name, nxt_month::text, (nxt_month + interval '1 month')::date::text);

  -- Ensure child indexes exist on the partition
  EXECUTE format('CREATE INDEX IF NOT EXISTS %I ON %I (author_id)', part_name||'_author_id_idx', part_name);
  EXECUTE format('CREATE INDEX IF NOT EXISTS %I ON %I (hash)',       part_name||'_hash_idx',       part_name);
  EXECUTE format('CREATE INDEX IF NOT EXISTS %I ON %I (city)',       part_name||'_city_idx',       part_name);
  EXECUTE format('CREATE INDEX IF NOT EXISTS %I ON %I (type_sell_or_rent)', part_name||'_type_idx', part_name);

  -- Attach partition indexes to parent partitioned indexes (idempotent)
  BEGIN
    EXECUTE format('ALTER INDEX idx_scrapped_ads_author_id ATTACH PARTITION %I', part_name||'_author_id_idx');
  EXCEPTION WHEN duplicate_object THEN NULL; END;
  BEGIN
    EXECUTE format('ALTER INDEX idx_scrapped_ads_hash ATTACH PARTITION %I', part_name||'_hash_idx');
  EXCEPTION WHEN duplicate_object THEN NULL; END;
  BEGIN
    EXECUTE format('ALTER INDEX idx_scrapped_ads_city ATTACH PARTITION %I', part_name||'_city_idx');
  EXCEPTION WHEN duplicate_object THEN NULL; END;
  BEGIN
    EXECUTE format('ALTER INDEX idx_scrapped_ads_type ATTACH PARTITION %I', part_name||'_type_idx');
  EXCEPTION WHEN duplicate_object THEN NULL; END;

  -- Optional: ensure DEFAULT partition exists as a safety net
  EXECUTE 'CREATE TABLE IF NOT EXISTS scrapped_ads_default PARTITION OF scrapped_ads DEFAULT';
END
$$;
