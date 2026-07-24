#!/usr/bin/env python3

import gzip
import json
import os
import sys
from datetime import datetime
from pathlib import Path

import polars as pl

__version__ = "0.1.0"


def parse_diamond(result_dir: str | Path, sample_name: str):
    json_parse = {
        "meta_data": {"version": __version__, "module": "vfdb", "date": None, "sample": sample_name},
        "data": None,
    }

    path = Path(result_dir)
    date = datetime.fromtimestamp(os.path.getctime(path))
    json_parse["meta_data"]["date"] = str(date).split()[0]

    columns = [
        "qseqid",
        "sseqid",
        "qlen",
        "slen",
        "qstart",
        "qend",
        "sstart",
        "send",
        "length",
        "pident",
        "evalue",
        "bitscore",
    ]

    try:
        df = pl.read_csv(result_dir, separator="\t", new_columns=columns, infer_schema_length=None)
    except pl.exceptions.NoDataError:
        df = pl.DataFrame(schema=columns)

    json_parse["data"] = df.to_dict(as_series=False)

    with gzip.open(f"{sample_name}.json.gz", "wt", encoding="utf-8") as f:
        json.dump(json_parse, f, ensure_ascii=False, separators=(",", ":"), indent=4)


if __name__ == "__main__":
    result_dir = Path(sys.argv[1])
    sample_name = sys.argv[2]
    parse_diamond(result_dir, sample_name)
