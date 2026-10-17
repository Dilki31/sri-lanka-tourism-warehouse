"""Create the warehouse tables from sql/schema.sql."""
from pathlib import Path

from sqlalchemy import text

from db import get_engine

SCHEMA_PATH = Path("sql/schema.sql")


def main() -> None:
    schema_sql = SCHEMA_PATH.read_text(encoding="utf-8")
    engine = get_engine()

    # One transaction: either all tables are created or none
    with engine.begin() as connection:
        connection.execute(text(schema_sql))

    print("Schema created: dim_country, dim_date, fact_arrivals_ytd")


if __name__ == "__main__":
    main()