"""Load SLTDA arrivals data from the CSV file into the star schema."""
import calendar
from pathlib import Path

import pandas as pd
from sqlalchemy import text

from db import get_engine

CSV_PATH = Path("data/arrivals_ytd.csv")
REQUIRED_COLUMNS = {"report_date", "rank", "country", "tourists_ytd"}

# Our own grouping of source markets (SLTDA uses different region names)
REGIONS = {
    "India": "South Asia",
    "Bangladesh": "South Asia",
    "Maldives": "South Asia",
    "Pakistan": "South Asia",
    "United Kingdom": "Europe",
    "Russian Federation": "Europe",
    "Germany": "Europe",
    "France": "Europe",
    "Poland": "Europe",
    "Netherlands": "Europe",
    "Italy": "Europe",
    "Switzerland": "Europe",
    "Spain": "Europe",
    "China": "East & Southeast Asia",
    "Japan": "East & Southeast Asia",
    "Malaysia": "East & Southeast Asia",
    "United States": "North America",
    "Canada": "North America",
    "Australia": "Oceania",
    "Israel": "Middle East",
}

UPSERT_COUNTRY = """
INSERT INTO dim_country (country_name, region)
VALUES (:country_name, :region)
ON CONFLICT (country_name) DO UPDATE SET region = EXCLUDED.region;
"""

UPSERT_DATE = """
INSERT INTO dim_date (date_key, full_date, year, quarter, month, month_name)
VALUES (:date_key, :full_date, :year, :quarter, :month, :month_name)
ON CONFLICT (date_key) DO NOTHING;
"""

UPSERT_FACT = """
INSERT INTO fact_arrivals_ytd (date_key, country_key, tourists_ytd, source_rank)
SELECT :date_key, c.country_key, :tourists_ytd, :source_rank
FROM dim_country AS c
WHERE c.country_name = :country_name
ON CONFLICT (date_key, country_key) DO UPDATE SET
    tourists_ytd = EXCLUDED.tourists_ytd,
    source_rank  = EXCLUDED.source_rank;
"""


def validate(df: pd.DataFrame) -> None:
    """Stop with a clear message if the CSV has problems."""
    missing = REQUIRED_COLUMNS - set(df.columns)
    if missing:
        raise ValueError(f"CSV is missing columns: {sorted(missing)}")
    if df[list(REQUIRED_COLUMNS)].isna().any().any():
        raise ValueError("CSV contains empty values")
    if (df["tourists_ytd"] < 0).any():
        raise ValueError("CSV contains negative tourist counts")
    if df.duplicated(["report_date", "country"]).any():
        raise ValueError("CSV contains a country twice for the same date")
    unknown = set(df["country"]) - set(REGIONS)
    if unknown:
        raise ValueError(f"Add these countries to REGIONS: {sorted(unknown)}")


def main() -> None:
    df = pd.read_csv(CSV_PATH, parse_dates=["report_date"])
    df["country"] = df["country"].str.strip()
    validate(df)

    countries = [
        {"country_name": name, "region": REGIONS[name]}
        for name in sorted(df["country"].unique())
    ]
    dates = []
    for day in sorted(df["report_date"].unique()):
        day = pd.Timestamp(day)
        dates.append(
            {
                "date_key": int(day.strftime("%Y%m%d")),
                "full_date": day.date(),
                "year": day.year,
                "quarter": (day.month - 1) // 3 + 1,
                "month": day.month,
                "month_name": calendar.month_name[day.month],
            }
        )
    facts = [
        {
            "date_key": int(row.report_date.strftime("%Y%m%d")),
            "country_name": row.country,
            "tourists_ytd": int(row.tourists_ytd),
            "source_rank": int(row.rank),
        }
        for row in df.itertuples()
    ]

    engine = get_engine()
    # One transaction: if anything fails, nothing is saved halfway
    with engine.begin() as connection:
        connection.execute(text(UPSERT_COUNTRY), countries)
        connection.execute(text(UPSERT_DATE), dates)
        connection.execute(text(UPSERT_FACT), facts)
        counts = {
            table: connection.execute(text(f"SELECT COUNT(*) FROM {table};")).scalar()
            for table in ("dim_country", "dim_date", "fact_arrivals_ytd")
        }

    print("Load complete. Row counts:", counts)


if __name__ == "__main__":
    main()