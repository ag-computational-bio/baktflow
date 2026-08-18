#!/usr/bin/env python3

import json
import os
import sys
from datetime import datetime
from pathlib import Path

import polars as pl
from versions import get_module_tool_versions
from xopen import xopen


def parse_silva16s(result_dir: Path, sample_name: str):
    date: str = str(datetime.fromtimestamp(os.path.getctime(Path(result_dir)))).split()[0]

    columns = ["qseqid", "sseqid", "length", "nident", "bitscore", "stitle"]

    try:
        df = pl.read_csv(result_dir, separator="\t")
        df = df[:, :6]
        df.columns = columns
    except pl.exceptions.NoDataError:
        df = pl.DataFrame(schema=columns)

    data = df.to_dict(as_series=False)

    json_parse = {
        "meta_data": {"version": get_module_tool_versions("silva-16s"), "module": "silva-16s", "date": date,
                      "sample": sample_name},
        "data": data,
    }
    with xopen(f"report-{sample_name}.json.gz", "wt", compresslevel=9) as f:
        json.dump(json_parse, f, ensure_ascii=False, separators=(",", ":"), indent=4)


if __name__ == "__main__":
    result_dir = Path(sys.argv[1])
    sample_name = sys.argv[2]
    parse_silva16s(result_dir, sample_name)
