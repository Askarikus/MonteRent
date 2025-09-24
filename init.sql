-- Bootstrap schema and set search_path
CREATE SCHEMA IF NOT EXISTS public;
SET search_path TO public;

-- Authors
CREATE TABLE IF NOT EXISTS authors (
  id BIGSERIAL NOT NULL,
  telegram_user_id VARCHAR(32) NOT NULL,
  name VARCHAR(255) DEFAULT NULL,
  created_at TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL,
  updated_at TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL,
  PRIMARY KEY (id)
);
CREATE UNIQUE INDEX IF NOT EXISTS UNIQ_8E0C2A51FC28B263 ON authors (telegram_user_id);
COMMENT ON COLUMN authors.created_at IS '(DC2Type:datetime_immutable)';
COMMENT ON COLUMN authors.updated_at IS '(DC2Type:datetime_immutable)';

-- Refresh tokens
CREATE TABLE IF NOT EXISTS refresh_tokens (
  id SERIAL NOT NULL,
  refresh_token VARCHAR(128) NOT NULL,
  username VARCHAR(255) NOT NULL,
  valid TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL,
  PRIMARY KEY (id)
);
CREATE UNIQUE INDEX IF NOT EXISTS UNIQ_9BACE7E1C74F2195 ON refresh_tokens (refresh_token);

-- Scrapped ads (partitioned by month on created_at)
CREATE TABLE IF NOT EXISTS scrapped_ads (
  id BIGSERIAL NOT NULL,
  author_id BIGINT DEFAULT NULL,
  hash VARCHAR(255) NOT NULL,
  type_sell_or_rent VARCHAR(255) NOT NULL,
  city VARCHAR(255) NOT NULL,
  telegram_group_name VARCHAR(255) NOT NULL,
  subregion VARCHAR(255) DEFAULT NULL,
  message_text VARCHAR(20000) NOT NULL,
  message_corrected_text VARCHAR(20000) DEFAULT NULL,
  price DOUBLE PRECISION DEFAULT NULL,
  photo_path VARCHAR(255) DEFAULT NULL,
  latitude NUMERIC(9, 6) DEFAULT NULL,
  longitude NUMERIC(9, 6) DEFAULT NULL,
  address VARCHAR(255) DEFAULT NULL,
  published_at JSON NOT NULL,
  telegram_message_id INT NOT NULL,
  telegram_topic_id INT DEFAULT NULL,
  telegram_user_id VARCHAR(32) NOT NULL,
  message_hashtags_entities JSON DEFAULT NULL,
  message_phones_entities JSON DEFAULT NULL,
  hashtags JSON DEFAULT NULL,
  phones JSON DEFAULT NULL,
  omitted_by_admin_at TIMESTAMP(0) WITHOUT TIME ZONE DEFAULT NULL,
  is_search_ad BOOLEAN DEFAULT NULL,
  is_spam BOOLEAN DEFAULT NULL,
  area_square_meters DOUBLE PRECISION DEFAULT NULL,
  bedrooms INT DEFAULT NULL,
  ai_rating INT DEFAULT NULL,
  scalar BIGINT DEFAULT NULL,
  created_at TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL,
  updated_at TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL,
  PRIMARY KEY (id)
) PARTITION BY RANGE (created_at);

-- Partitioned indexes (создаются как индекс-родитель и будут иметь потомков на партициях)
CREATE INDEX IF NOT EXISTS idx_scrapped_ads_author_id ON scrapped_ads (author_id);
CREATE INDEX IF NOT EXISTS idx_scrapped_ads_hash ON scrapped_ads (hash);
CREATE INDEX IF NOT EXISTS idx_scrapped_ads_city ON scrapped_ads (city);
CREATE INDEX IF NOT EXISTS idx_scrapped_ads_type ON scrapped_ads (type_sell_or_rent);

COMMENT ON COLUMN scrapped_ads.omitted_by_admin_at IS '(DC2Type:datetime_immutable)';
COMMENT ON COLUMN scrapped_ads.created_at IS '(DC2Type:datetime_immutable)';
COMMENT ON COLUMN scrapped_ads.updated_at IS '(DC2Type:datetime_immutable)';

-- Ensure current and next month partitions exist, plus DEFAULT partition
DO $$
DECLARE
  cur_month date := date_trunc('month', now())::date;
  nxt_month date := (date_trunc('month', now()) + interval '1 month')::date;
  part_name text;
BEGIN
  -- current month
  part_name := format('scrapped_ads_y%sm%s', to_char(cur_month, 'YYYY'), to_char(cur_month, 'MM'));
  EXECUTE format($f$
    CREATE TABLE IF NOT EXISTS %I PARTITION OF scrapped_ads
    FOR VALUES FROM (%L) TO (%L)
  $f$, part_name, cur_month::text, (cur_month + interval '1 month')::date::text);
  -- ensure child indexes exist and are attached
  EXECUTE format('CREATE INDEX IF NOT EXISTS %I ON %I (author_id)', part_name||'_author_id_idx', part_name);
  EXECUTE format('CREATE INDEX IF NOT EXISTS %I ON %I (hash)',       part_name||'_hash_idx',       part_name);
  EXECUTE format('CREATE INDEX IF NOT EXISTS %I ON %I (city)',       part_name||'_city_idx',       part_name);
  EXECUTE format('CREATE INDEX IF NOT EXISTS %I ON %I (type_sell_or_rent)', part_name||'_type_idx', part_name);
  -- attach to partitioned indexes (ignore if already attached)
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

  -- next month
  part_name := format('scrapped_ads_y%sm%s', to_char(nxt_month, 'YYYY'), to_char(nxt_month, 'MM'));
  EXECUTE format($f$
    CREATE TABLE IF NOT EXISTS %I PARTITION OF scrapped_ads
    FOR VALUES FROM (%L) TO (%L)
  $f$, part_name, nxt_month::text, (nxt_month + interval '1 month')::date::text);
  -- ensure child indexes exist and are attached
  EXECUTE format('CREATE INDEX IF NOT EXISTS %I ON %I (author_id)', part_name||'_author_id_idx', part_name);
  EXECUTE format('CREATE INDEX IF NOT EXISTS %I ON %I (hash)',       part_name||'_hash_idx',       part_name);
  EXECUTE format('CREATE INDEX IF NOT EXISTS %I ON %I (city)',       part_name||'_city_idx',       part_name);
  EXECUTE format('CREATE INDEX IF NOT EXISTS %I ON %I (type_sell_or_rent)', part_name||'_type_idx', part_name);
  -- attach to partitioned indexes (ignore if already attached)
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

  -- default partition as a safety net
  EXECUTE 'CREATE TABLE IF NOT EXISTS scrapped_ads_default PARTITION OF scrapped_ads DEFAULT';
END
$$;

-- Translations
CREATE TABLE IF NOT EXISTS translations (
  id UUID NOT NULL,
  domain VARCHAR(50) NOT NULL,
  name VARCHAR(255) NOT NULL,
  translation VARCHAR(255) NOT NULL,
  created_at TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL,
  updated_at TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL,
  PRIMARY KEY (id)
);
COMMENT ON COLUMN translations.id IS '(DC2Type:uuid)';
COMMENT ON COLUMN translations.created_at IS '(DC2Type:datetime_immutable)';
COMMENT ON COLUMN translations.updated_at IS '(DC2Type:datetime_immutable)';

-- Users
CREATE TABLE IF NOT EXISTS users (
  id UUID NOT NULL,
  name VARCHAR(255) DEFAULT NULL,
  email VARCHAR(255) NOT NULL,
  password VARCHAR(255) NOT NULL,
  roles JSON NOT NULL,
  created_at TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL,
  updated_at TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL,
  PRIMARY KEY (id)
);
CREATE UNIQUE INDEX IF NOT EXISTS UNIQ_1483A5E9E7927C74 ON users (email);
COMMENT ON COLUMN users.id IS '(DC2Type:uuid)';
COMMENT ON COLUMN users.created_at IS '(DC2Type:datetime_immutable)';
COMMENT ON COLUMN users.updated_at IS '(DC2Type:datetime_immutable)';

-- Visitors
CREATE TABLE IF NOT EXISTS visitors (
  id UUID NOT NULL,
  ip VARCHAR(45) NOT NULL,
  last_visited_at TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL,
  visits_count INT DEFAULT 0 NOT NULL,
  last_path VARCHAR(2048) DEFAULT NULL,
  created_at TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL,
  updated_at TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL,
  PRIMARY KEY (id)
);
COMMENT ON COLUMN visitors.id IS '(DC2Type:uuid)';
COMMENT ON COLUMN visitors.last_visited_at IS '(DC2Type:datetime_immutable)';
COMMENT ON COLUMN visitors.created_at IS '(DC2Type:datetime_immutable)';
COMMENT ON COLUMN visitors.updated_at IS '(DC2Type:datetime_immutable)';

-- Foreign keys
ALTER TABLE scrapped_ads
  ADD CONSTRAINT FK_3EC69B09F675F31B
  FOREIGN KEY (author_id) REFERENCES authors (id)
  ON DELETE SET NULL
  NOT DEFERRABLE INITIALLY IMMEDIATE;
