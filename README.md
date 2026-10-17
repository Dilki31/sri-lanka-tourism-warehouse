# Sri Lanka Tourism Data Warehouse

A small data warehouse built with Python and PostgreSQL. It stores Sri Lanka's top tourist source markets in a star schema and answers questions about them with SQL.

## Data source

The data is the **Top twenty source markets, 1 January to 30 June 2026** table from the [SLTDA Weekly Report (1st to 30th June 2026)](https://www.sltda.gov.lk/storage/common_media/Weekly_Report_1st_to_30th_June_2026.pdf). SLTDA publishes these reports as PDFs, so the table was entered by hand into `data/arrivals_ytd.csv` and checked against the report. The region grouping of countries is my own, not SLTDA's.

## Schema (star schema)

```
dim_country (country_key, country_name, region)
dim_date    (date_key, full_date, year, quarter, month, month_name)
fact_arrivals_ytd (date_key, country_key, tourists_ytd, source_rank)
```

The fact table holds cumulative tourist counts per country per report date, and links to the two dimension tables by foreign keys. It has a composite primary key and an index on `country_key`.

## Project structure

```
sri-lanka-tourism-warehouse/
├── data/arrivals_ytd.csv   # hand-collected source data
├── sql/schema.sql          # table definitions
├── sql/queries.sql         # analysis queries
├── db.py                   # shared database connection
├── create_schema.py        # create the tables
├── load_data.py            # validate the CSV and load the warehouse
├── test_connection.py      # check the database connection
├── requirements.txt        # Python dependencies
└── .env.example            # example database settings
```

## How to run

1. Clone the repository and install the libraries:
```
   git clone https://github.com/Dilki31/sri-lanka-tourism-warehouse.git
   cd sri-lanka-tourism-warehouse
   python -m venv venv
   venv\Scripts\activate
   python -m pip install -r requirements.txt
```
2. Create an empty PostgreSQL database named `sl_tourism_db`.
3. Copy `.env.example` to `.env` and enter your own password.
4. Create the tables and load the data:
```
   python create_schema.py
   python load_data.py
```
   The load validates the CSV first and is safe to run repeatedly, because it upserts rows instead of duplicating them.

## Example results

Tourists by region (from `sql/queries.sql`):

| Region                | Markets | Tourists (Jan to Jun 2026) | % of top 20 |
|-----------------------|---------|----------------------------|-------------|
| Europe                | 9       | 398,067                    | 40.9        |
| South Asia            | 4       | 343,703                    | 35.3        |
| East & Southeast Asia | 3       | 106,787                    | 11.0        |
| Oceania               | 1       | 57,436                     | 5.9         |
| North America         | 2       | 55,280                     | 5.7         |
| Middle East           | 1       | 11,124                     | 1.1         |

- Europe is the largest region because it has nine markets, but India alone is the largest single market at 30.2% of the top-20 total.
- The percentages are shares of the **top-20 total** (972,397 tourists), not of all arrivals.

## Limitations and next steps

- The warehouse currently holds one snapshot, cumulative to 30 June 2026. Adding more monthly reports would allow monthly arrivals to be derived with SQL window functions.
- The data is entered by hand, so each new report needs a careful check.

## Monthly arrivals with `LAG`

The SLTDA reports publish **cumulative year-to-date** figures, so monthly arrivals
are not stored directly. They are derived in SQL with a window function:

```sql
tourists_ytd - LAG(tourists_ytd) OVER (PARTITION BY country_key ORDER BY full_date)
```

The query (Query 4 in `sql/queries.sql`) only subtracts when the previous row is
from the immediately preceding month, so a country that drops out of the top 20
for a month never produces a wrong figure.

## Data notes and limitations

- Only the top 20 source markets per report are loaded, so the totals are
  not total national arrivals.
- Countries can enter or leave the top 20 between months, so monthly figures
  exist only for countries present in two consecutive reports.
- Currently loaded: May and June 2026. More months can be added by appending rows to
  `data/arrivals_ytd.csv` and re-running `python load_data.py`. The load is idempotent.
- Report data is entered manually from the SLTDA PDFs. The loader validates
  missing values, duplicates, negative counts and unknown countries.

## Author

Dilki Ishara Nanayakkara, IT undergraduate at Institute of Technology University of Moratuwa
[GitHub](https://github.com/Dilki31) | [LinkedIn](https://www.linkedin.com/in/dilki-nanayakkara-16b539365)