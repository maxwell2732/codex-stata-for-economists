# Data Dictionary

> Use this template for `data/README.md` in your fork. Document every dataset
> in `data/raw/` and `data/derived/`. Keep entries concise — one block per file.

## Conventions

- **Variable names:** snake_case
- **Missing values:** `.` for numeric, `""` for string (Stata default)
- **Date format:** `YYYY-MM-DD` (ISO 8601) or Stata `%td` daily
- **Currency:** specify nominal vs. real, base year for real, currency code

---

## Raw Datasets

### `data/raw/[FILENAME].dta`

| Field | Value |
|---|---|
| **Source** | [Full URL, agency, paper, etc.] |
| **Vintage** | [Date downloaded] |
| **License** | [Public / Restricted / Proprietary — terms] |
| **Unit of observation** | [Person / firm / county-year / etc.] |
| **Sample period** | [YYYY–YYYY] |
| **N rows** | [Count] |
| **N variables** | [Count] |
| **Loaded by** | `dofiles/01_clean/[script].do` |
| **Documentation** | [Link to codebook, if external] |
| **Notes** | [Quirks: known missingness, encoding issues, surveys/waves] |

#### Key variables

| Variable | Type | Description | Notes |
|---|---|---|---|
| `id` | int | Unit identifier | unique within year |
| `year` | int | Survey year | 2000–2020 |
| `outcome_var` | float | Outcome of interest | in $ thousands |

---

## Derived Datasets

### `data/derived/[FILENAME].dta`

| Field | Value |
|---|---|
| **Produced by** | `dofiles/02_construct/[script].do` |
| **Inputs** | `data/raw/...`, `data/derived/...` |
| **Sample restrictions** | [What's been dropped/kept and why] |
| **N rows** | [After restrictions] |
| **Used by** | `dofiles/03_analysis/[scripts].do` |

#### Constructed variables

| Variable | Construction | Comment |
|---|---|---|
| `treated` | 1 if ever in treatment group | per Section 3 of paper |
| `post` | 1 if year ≥ treatment year | |
| `log_y` | log(outcome + 1) | smooths zeros |
