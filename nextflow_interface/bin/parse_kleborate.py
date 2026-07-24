#!/usr/bin/env python3

import gzip
import json
import os
import sys
from datetime import datetime
from pathlib import Path

import polars as pl

__version__ = "0.1.0"


def parse_kleborate(result_dir: str | Path, sample_name: str):
    json_parse = {
        "meta_data": {"version": __version__, "module": "kleborate", "date": None, "sample": sample_name},
        "data": None,
    }

    path = Path(result_dir)
    date = datetime.fromtimestamp(os.path.getctime(path))
    json_parse["meta_data"]["date"] = str(date).split()[0]

    try:
        df = pl.read_csv(result_dir, separator="\t")
        df.columns = [col.lower() for col in df.columns]
    except pl.exceptions.NoDataError:
        df = pl.DataFrame()

    json_parse["data"] = df.to_dict(as_series=False)

    with gzip.open(f"{sample_name}.json.gz", "wt", encoding="utf-8") as f:
        json.dump(json_parse, f, ensure_ascii=False, separators=(",", ":"), indent=4)


if __name__ == "__main__":
    result_dir = Path(sys.argv[1])
    sample_name = sys.argv[2]
    parse_kleborate(result_dir, sample_name)
