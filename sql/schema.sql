-- Star schema for the Sri Lanka tourism data warehouse

CREATE TABLE IF NOT EXISTS dim_country (
    country_key  SERIAL PRIMARY KEY,
    country_name VARCHAR(60) NOT NULL UNIQUE,
    region       VARCHAR(40) NOT NULL
);

CREATE TABLE IF NOT EXISTS dim_date (
    date_key   INTEGER PRIMARY KEY,
    full_date  DATE NOT NULL UNIQUE,
    year       SMALLINT NOT NULL,
    quarter    SMALLINT NOT NULL,
    month      SMALLINT NOT NULL,
    month_name VARCHAR(10) NOT NULL
);

CREATE TABLE IF NOT EXISTS fact_arrivals_ytd (
    date_key     INTEGER NOT NULL REFERENCES dim_date (date_key),
    country_key  INTEGER NOT NULL REFERENCES dim_country (country_key),
    tourists_ytd INTEGER NOT NULL CHECK (tourists_ytd >= 0),
    source_rank  SMALLINT NOT NULL CHECK (source_rank >= 1),
    PRIMARY KEY (date_key, country_key)
);

CREATE INDEX IF NOT EXISTS idx_fact_country ON fact_arrivals_ytd (country_key);