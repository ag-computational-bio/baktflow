#!/usr/bin/env python3

import json
import os
import sys
from datetime import datetime
from pathlib import Path

import polars as pl
from versions import get_module_tool_versions
from xopen import xopen


def parse_checkm2(result_dir: str | Path, sample_name: str):
    date: str = str(datetime.fromtimestamp(os.path.getctime(Path(result_dir)))).split()[0]

    columns = ["name", "completeness", "contamination", "completeness_model_used", "additional_notes"]
    try:
        df = pl.read_csv(result_dir, separator="\t", new_columns=columns)
    except pl.exceptions.NoDataError:
        df = pl.DataFrame(schema=columns)

    data = df.to_dict(as_series=False)

    json_parse = {
        "meta_data": {"version": get_module_tool_versions("checkm2"), "module": "checkm2", "date": date,
                      "sample": sample_name},
        "data": data,
    }
    with xopen(f"report-{sample_name}.json.gz", "wt", compresslevel=9) as f:
        json.dump(json_parse, f, ensure_ascii=False, separators=(",", ":"), indent=4)


if __name__ == "__main__":
    result_dir = Path(sys.argv[1])
    sample_name = sys.argv[2]
    parse_checkm2(result_dir, sample_name)
