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


def parse_checkm2(result_dir: str | Path, sample_name: str):
    json_parse = {
        "meta_data": {"version": __version__, "module": "checkm2", "date": None, "sample": sample_name},
        "data": None,
    }

    path = Path(result_dir)
    date = datetime.fromtimestamp(os.path.getctime(path))
    json_parse["meta_data"]["date"] = str(date).split()[0]

    columns = ["name", "completeness", "contamination", "completeness_model_used", "additional_notes"]

    try:
        df = pl.read_csv(result_dir, separator="\t", new_columns=columns)
    except pl.exceptions.NoDataError:
        df = pl.DataFrame(schema=columns)

    json_parse["data"] = df.to_dict(as_series=False)

    with gzip.open(f"{sample_name}.json.gz", "wt", encoding="utf-8") as f:
        json.dump(json_parse, f, ensure_ascii=False, separators=(",", ":"), indent=4)


if __name__ == "__main__":
    result_dir = Path(sys.argv[1])
    sample_name = sys.argv[2]
    parse_checkm2(result_dir, sample_name)
