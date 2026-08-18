#!/usr/bin/env python3

import json
import os
import sys
from datetime import datetime
from pathlib import Path

import polars as pl
from versions import get_module_tool_versions
from xopen import xopen


def parse_genomestats(
        result_dir: str | Path, sample_name: str, sample_type: str, result_hybrid: str | Path | None = None
):
    date: str = str(datetime.fromtimestamp(os.path.getctime(Path(result_dir)))).split()[0]

    columns = ["file", "n_reads", "bp", "avg_length", "n50", "n75", "n90", "aun", "min", "max"]

    if sample_type in ("long", "short"):
        try:
            df_long = pl.read_csv(result_dir, separator="\t", has_header=False, new_columns=columns)
        except pl.exceptions.NoDataError:
            df_long = pl.DataFrame(schema=columns)

        data = df_long.to_dict(as_series=False)

    else:
        try:
            df_long = pl.read_csv(result_dir, separator="\t", has_header=False, new_columns=columns)
            if result_hybrid:
                df_short = pl.read_csv(result_hybrid, separator="\t", has_header=False, new_columns=columns)

        except pl.exceptions.NoDataError:
            df_long = pl.DataFrame(schema=columns)
            df_short = pl.DataFrame(schema=columns)

        data = {
            "long": df_long.to_dict(as_series=False),
            "short": df_short.to_dict(as_series=False)
        }

    json_parse = {
        "meta_data": {"version": get_module_tool_versions("genomestats"), "module": "genomestats", "date": date,
                      "sample": sample_name},
        "data": data,
    }

    with xopen(f"report-{sample_name}.json.gz", "wt", compresslevel=9) as f:
        json.dump(json_parse, f, ensure_ascii=False, separators=(",", ":"), indent=4)


if __name__ == "__main__":
    result_dir = Path(sys.argv[1])
    sample_name = sys.argv[2]
    sample_type = sys.argv[3]
    result_hybrid = sys.argv[4] if len(sys.argv) > 4 else None
    parse_genomestats(result_dir, sample_name, sample_type, result_hybrid)
