#!/usr/bin/env python3

import json
import os
import sys
from datetime import datetime
from pathlib import Path

import polars as pl
from versions import get_module_tool_versions
from xopen import xopen


def parse_mob(result_dir: str | Path, sample_name: str):
    date: str = str(datetime.fromtimestamp(os.path.getctime(Path(result_dir)))).split()[0]

    columns = [
        "sample_id",
        "molecule_type",
        "primary_cluster_id",
        "secondary_cluster_id",
        "contig_id",
        "size",
        "gc",
        "md5",
        "circularity_status",
        "rep_type",
        "rep_type_accession",
        "relaxase_type",
        "relaxase_type_accession",
        "mpf_type",
        "mpf_type_accession",
        "orit_type",
        "orit_accession",
        "predicted_mobility",
        "mash_nearest_neighbor",
        "mash_neighbor_distance",
        "mash_neighbor_identification",
        "repetitive_dna_id",
        "repetitive_dna_type",
        "filtering_reason",
    ]

    schema = {col: pl.String for col in columns}

    try:
        df = pl.read_csv(result_dir, separator="\t", new_columns=columns, schema=schema)
    except pl.exceptions.NoDataError:
        df = pl.DataFrame(schema=schema)

    data = df.to_dict(as_series=False)

    json_parse = {
        "meta_data": {"version": get_module_tool_versions("mob_suite"), "module": "mob_suite", "date": date,
                      "sample": sample_name},
        "data": data,
    }

    with xopen(f"report-{sample_name}.json.gz", "wt", compresslevel=9) as f:
        json.dump(json_parse, f, ensure_ascii=False, separators=(",", ":"), indent=4)


if __name__ == "__main__":
    result_dir = Path(sys.argv[1])
    sample_name = sys.argv[2]
    parse_mob(result_dir, sample_name)
