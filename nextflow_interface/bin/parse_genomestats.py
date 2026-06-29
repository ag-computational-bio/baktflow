#!/usr/bin/env python3

import os
import json
import sys
import polars as pl
from pathlib import Path
from datetime import datetime
import gzip


def parse_genomestats(result_dir:str, sample_name:str, sample_type:str, result_short=None):

    json_parse = {
        "meta_data": {
            "version": "baktflow 0.1.0", # version command, env files
            "module": "genomestats",
            "date": None,
            "sample": sample_name
        },
        "data": {}
    }

    path = Path(result_dir)
    date  = datetime.fromtimestamp(os.path.getctime(path))
    json_parse["meta_data"]["date"] = str(date).split()[0]


    if sample_type in ("long", "short"):
        df_long = pl.read_csv(result_dir,
                         separator="\t",
                         new_columns=["file", "n_reads", "bp", "avg_length", "n50", "n75", "n90", "aun", "min", "max"])

        json_parse["data"] = df_long.to_dict(as_series=False)

    else:
        df_long = pl.read_csv(result_dir,
                              separator="\t",
                              new_columns=["file", "n_reads", "bp", "avg_length", "n50", "n75", "n90", "aun", "min", "max"])
        df_short = pl.read_csv(result_short,
                              separator="\t",
                              new_columns=["file", "n_reads", "bp", "avg_length", "n50", "n75", "n90", "aun", "min", "max"])

        json_parse["data"]["long"] = df_long.to_dict(as_series=False)
        json_parse["data"]["short"] = df_short.to_dict(as_series=False)

    with gzip.open(f"{sample_name}.json.gz", "wt", encoding="utf-8") as f:
        json.dump(json_parse, f, ensure_ascii=False, separators=(",", ":"), indent=4)


if __name__ == "__main__":
    result_dir = Path(sys.argv[1])
    sample_name = sys.argv[2]
    sample_type = sys.argv[3]
    result_short = sys.argv[4]
    parse_genomestats(result_dir, sample_name, sample_type, result_short)
