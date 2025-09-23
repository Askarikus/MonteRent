-- Enable UUID generation (pgcrypto)
CREATE SCHEMA IF NOT EXISTS public;
SET search_path TO public;
CREATE EXTENSION IF NOT EXISTS pgcrypto;

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

-- Scrapped ads
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
);
CREATE INDEX IF NOT EXISTS IDX_3EC69B09F675F31B ON scrapped_ads (author_id);
CREATE UNIQUE INDEX IF NOT EXISTS uniq_scrapped_ads_hash ON scrapped_ads (hash);
COMMENT ON COLUMN scrapped_ads.omitted_by_admin_at IS '(DC2Type:datetime_immutable)';
COMMENT ON COLUMN scrapped_ads.created_at IS '(DC2Type:datetime_immutable)';
COMMENT ON COLUMN scrapped_ads.updated_at IS '(DC2Type:datetime_immutable)';

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
