#!/usr/bin/env python3

import gzip
import json
import os
import sys
from datetime import datetime
from pathlib import Path

import polars as pl
from utils import get_version

__version__ = get_version()


def parse_genomestats(
    result_dir: str | Path, sample_name: str, sample_type: str, result_hybrid: str | Path | None = None
):
    json_parse = {
        "meta_data": {"version": __version__, "module": "genomestats", "date": None, "sample": sample_name},
        "data": {},
    }

    path = Path(result_dir)
    date = datetime.fromtimestamp(os.path.getctime(path))
    json_parse["meta_data"]["date"] = str(date).split()[0]

    columns = ["file", "n_reads", "bp", "avg_length", "n50", "n75", "n90", "aun", "min", "max"]

    if sample_type in ("long", "short"):
        try:
            df_long = pl.read_csv(result_dir, separator="\t", has_header=False, new_columns=columns)
        except pl.exceptions.NoDataError:
            df_long = pl.DataFrame(schema=columns)

        json_parse["data"] = df_long.to_dict(as_series=False)

    else:
        try:
            df_long = pl.read_csv(result_dir, separator="\t", has_header=False, new_columns=columns)
            if result_hybrid:
                df_short = pl.read_csv(result_hybrid, separator="\t", has_header=False, new_columns=columns)

            # print(df_long)
            # print(df_short)

        except pl.exceptions.NoDataError:
            df_long = pl.DataFrame(schema=columns)
            df_short = pl.DataFrame(schema=columns)

        json_parse["data"]["long"] = df_long.to_dict(as_series=False)
        json_parse["data"]["short"] = df_short.to_dict(as_series=False)

    with gzip.open(f"{sample_name}.json.gz", "wt", encoding="utf-8") as f:
        json.dump(json_parse, f, ensure_ascii=False, separators=(",", ":"), indent=4)


if __name__ == "__main__":
    result_dir = Path(sys.argv[1])
    sample_name = sys.argv[2]
    sample_type = sys.argv[3]
    result_hybrid = sys.argv[4] if len(sys.argv) > 4 else None
    parse_genomestats(result_dir, sample_name, sample_type, result_hybrid)
