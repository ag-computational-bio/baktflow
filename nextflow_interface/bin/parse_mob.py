#!/usr/bin/env python3

import gzip
import json
import os
import sys
from datetime import datetime
from pathlib import Path

import polars as pl

__version__ = "0.1.0"


def parse_mob(result_dir: str | Path, sample_name: str):
    json_parse = {
        "meta_data": {"version": __version__, "module": "diamond", "date": None, "sample": sample_name},
        "data": None,
    }

    path = Path(result_dir)
    date = datetime.fromtimestamp(os.path.getctime(path))
    json_parse["meta_data"]["date"] = str(date).split()[0]

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

    json_parse["data"] = df.to_dict(as_series=False)

    with gzip.open(f"{sample_name}.json.gz", "wt", encoding="utf-8") as f:
        json.dump(json_parse, f, ensure_ascii=False, separators=(",", ":"), indent=4)


if __name__ == "__main__":
    result_dir = Path(sys.argv[1])
    sample_name = sys.argv[2]
    parse_mob(result_dir, sample_name)
