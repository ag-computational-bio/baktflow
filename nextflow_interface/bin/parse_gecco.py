#!/usr/bin/env python3

import os
import json
import polars as pl
from pathlib import Path
from datetime import datetime
import gzip
import sys

def parse_ectyper(genes:str, features:str, cluster:str, sample_name:str):

    json_parse = {
        "meta_data": {
            "version": "baktflow 0.1.0", # version command, env files
            "module": "ectyper",
            "date": None,
            "sample": sample_name
        },
        "data": None
    }

    path_genes = Path(genes)
    date  = datetime.fromtimestamp(os.path.getctime(path_genes))
    json_parse["meta_data"]["date"] = str(date).split()[0]


    df_genes = pl.read_csv(genes, separator="\t")

    df_features =  pl.read_csv(features, separator="\t")

    df_cluster =  pl.read_csv(cluster, separator="\t")


    json_parse["data"].update({
        "genes": df_genes.to_dict(as_series=False),
        "features": df_features.to_dict(as_series=False),
        "cluster": df_cluster.to_dict(as_series=False)
    })

    with gzip.open(f"{sample_name}.json.gz", "wt", encoding="utf-8") as f:
        json.dump(json_parse, f, ensure_ascii=False, separators=(",", ":"), indent=4)


if __name__ == "__main__":
    # alle drei result files einlesen
    genes = Path(sys.argv[1])
    sample_name = sys.argv[2]
    parse_ectyper(genes, sample_name)