#!/usr/bin/env python3
"""
Build the narrow CHNS extract needed by the height-premium Stata do-file.

The source wide panel is large, so this script streams it once and writes only
the columns needed for the exploration to data/derived/, which is gitignored.
"""

from __future__ import annotations

import csv
import math
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
RAW_DIR = ROOT / "data" / "raw" / "CHNS_260521"
RAW = RAW_DIR / "chns_individual_wave_panel.csv"
WAGES = RAW_DIR / "wages_12.csv"
OUT = ROOT / "data" / "derived" / "chns_height_premium_core.csv"
WAGE_OUT = ROOT / "data" / "derived" / "chns_height_premium_wages.csv"

SELECTED = {
    "idind": "idind",
    "wave": "wave",
    "hhid": "hhid",
    "commid": "commid",
    "line": "line",
    "rst_12__idind_f": "father_id",
    "rst_12__idind_m": "mother_id",
    "mast_pub_12__gender": "gender",
    "surveys_pub_12__age": "age",
    "educ_12__a11": "educ_a11",
    "educ_12__a11a_93": "educ_a11a_93",
    "educ_12__a12": "educ_level",
    "jobs_13__b2": "working",
    "jobs_13__b4": "occupation",
    "jobs_13__b5": "employment_type",
    "jobs_13__b8": "hours_week",
    "pexam_pub_12__height": "height_cm",
    "pexam_pub_12__weight": "weight_kg",
    "urban_11__index": "urban_index",
    "rst_12__t1": "province",
    "rst_12__t2": "urban",
}


def main() -> int:
    OUT.parent.mkdir(parents=True, exist_ok=True)
    with RAW.open("r", newline="", encoding="utf-8-sig") as src:
        reader = csv.DictReader(src)
        if reader.fieldnames is None:
            raise RuntimeError(f"No header found in {RAW}")

        name_map = {name.lower(): name for name in reader.fieldnames}
        missing = [name for name in SELECTED if name not in name_map]
        if missing:
            raise RuntimeError("Missing required CHNS columns: " + ", ".join(missing))

        with OUT.open("w", newline="", encoding="utf-8") as dst:
            writer = csv.DictWriter(dst, fieldnames=list(SELECTED.values()))
            writer.writeheader()
            for row in reader:
                writer.writerow({
                    out: row.get(name_map[src_name], "")
                    for src_name, out in SELECTED.items()
                })

    wages: dict[tuple[str, str], dict[str, float | str]] = {}
    with WAGES.open("r", newline="", encoding="utf-8-sig") as src:
        reader = csv.DictReader(src)
        for row in reader:
            idind = row.get("IDind", "").strip()
            wave = row.get("WAVE", "").strip()
            if not idind or not wave:
                continue
            key = (idind, wave)
            current = wages.setdefault(
                key,
                {
                    "idind": idind,
                    "wave": wave,
                    "monthly_wage": 0.0,
                    "monthly_bonus": 0.0,
                    "any_wage_job": 0.0,
                },
            )
            wage = parse_positive(row.get("C8", ""), upper=999999)
            bonus = parse_positive(row.get("I19", ""), upper=999999)
            if wage is not None:
                current["monthly_wage"] = float(current["monthly_wage"]) + wage
                current["any_wage_job"] = max(float(current["any_wage_job"]), wage)
            if bonus is not None:
                current["monthly_bonus"] = float(current["monthly_bonus"]) + bonus / 12.0

    with WAGE_OUT.open("w", newline="", encoding="utf-8") as dst:
        fieldnames = [
            "idind",
            "wave",
            "monthly_wage",
            "monthly_bonus",
            "any_wage_job",
            "monthly_labor_income",
            "lmonthly_wage",
        ]
        writer = csv.DictWriter(dst, fieldnames=fieldnames)
        writer.writeheader()
        for row in wages.values():
            income = float(row["monthly_wage"]) + float(row["monthly_bonus"])
            if income <= 0:
                continue
            out = dict(row)
            out["monthly_labor_income"] = income
            out["lmonthly_wage"] = math.log(income)
            writer.writerow(out)

    print(f"wrote {OUT}")
    print(f"wrote {WAGE_OUT}")
    return 0


def parse_positive(value: str | None, upper: float) -> float | None:
    if value is None:
        return None
    try:
        parsed = float(value)
    except ValueError:
        return None
    if parsed <= 0 or parsed >= upper:
        return None
    return parsed


if __name__ == "__main__":
    raise SystemExit(main())
