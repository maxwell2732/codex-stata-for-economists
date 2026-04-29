# Data Directory

This directory holds **raw** and **derived** datasets for the Stata pipeline.

> **Privacy guarantee:** Everything under `data/raw/` and `data/derived/` is gitignored. Only this README and `.gitkeep` files reach GitHub. The pre-commit hook `scripts/check_data_safety.py` enforces this before every commit.

## Layout

```
data/
├── raw/                # Untouched source datasets — never edited, never committed
├── derived/            # Intermediate .dta produced by dofiles/01_clean and dofiles/02_construct
└── README.md           # This file (the data dictionary)
```

## Data dictionary template

Replace this placeholder with one entry per dataset.

### `data/raw/[FILENAME].dta`

| Field | Value |
|---|---|
| **Source** | [Where it came from — URL, agency, paper, etc.] |
| **Vintage** | [Date downloaded / version] |
| **Access restrictions** | [Public / restricted / proprietary — license terms] |
| **Unit of observation** | [Person / firm / county-year / etc.] |
| **Sample period** | [YYYY–YYYY] |
| **N rows** | [count] |
| **Loaded by** | `dofiles/01_clean/[script].do` |
| **Notes** | [Quirks, missingness, known issues] |

### `data/derived/[FILENAME].dta`

| Field | Value |
|---|---|
| **Produced by** | `dofiles/02_construct/[script].do` |
| **Inputs** | `data/raw/...`, `data/derived/...` |
| **Sample restrictions** | [What's been dropped/kept] |
| **N rows** | [after restrictions] |
| **Used by** | `dofiles/03_analysis/...` |
