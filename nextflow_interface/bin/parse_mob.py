#!/usr/bin/env python3

import os
import json
import sys
import polars as pl
from pathlib import Path
from datetime import datetime
import gzip

BASE_DIR = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(BASE_DIR))

from baktflow import __version__


def parse_mob(result_dir:str, sample_name:str):

    json_parse = {
        "meta_data": {
            "version": __version__,
            "module": "diamond",
            "date": None,
            "sample": sample_name
        },
        "data": None
    }

    path = Path(result_dir)
    date  = datetime.fromtimestamp(os.path.getctime(path))
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
        "filtering_reason"
    ]

    schema = {col: pl.String for col in columns}

    try:
        df = pl.read_csv(
            result_dir,
            separator="\t",
            new_columns=columns,
            schema=schema
        )
    except pl.exceptions.NoDataError:
        df = pl.DataFrame(schema=schema)



    json_parse["data"] = df.to_dict(as_series=False)


    with gzip.open(f"{sample_name}.json.gz", "wt", encoding="utf-8") as f:
        json.dump(json_parse, f, ensure_ascii=False, separators=(",", ":"), indent=4)



if __name__ == "__main__":
    result_dir = Path(sys.argv[1])
    sample_name = sys.argv[2]
    parse_mob(result_dir, sample_name)
