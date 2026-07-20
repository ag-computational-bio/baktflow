#!/usr/bin/env python3

import os
import json
import polars as pl
from pathlib import Path
from datetime import datetime
import gzip
import sys

BASE_DIR = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(BASE_DIR))

from baktflow import __version__

def parse_gecco(genes:str, features:str, cluster:str, sample_name:str):

    json_parse = {
        "meta_data": {
            "version": __version__,
            "module": "gecco",
            "date": None,
            "sample": sample_name
        },
        "data": {}
    }

    path_genes = Path(genes)
    date  = datetime.fromtimestamp(os.path.getctime(path_genes))
    json_parse["meta_data"]["date"] = str(date).split()[0]


    df_genes = pl.read_csv(genes, separator="\t",
                           new_columns=["sequence_id", "protein_id", "start", "end", "strand", "average_p", "max_p"])

    df_features =  pl.read_csv(features, separator="\t",
                               new_columns=["sequence_id", "protein_id", "start", "end", "strand", "domain", "hmm", "i_evalue",
                                            "p_value", "domain_start", "domain_end", "cluster_probability"])

    df_cluster =  pl.read_csv(cluster, separator="\t",
                              new_columns=["sequence_id", "cluster_id", "start", "end", "average_p", "max_p", "type",
                                           "alkaloid_probability", "nrp_probability", "polyketide_probability",
                                           "ripp_probability", "saccharide_probability", "terpene_probability",
                                           "proteins", "domains"])


    json_parse["data"].update({
        "genes": df_genes.to_dict(as_series=False),
        "features": df_features.to_dict(as_series=False),
        "cluster": df_cluster.to_dict(as_series=False)
    })

    with gzip.open(f"{sample_name}.json.gz", "wt", encoding="utf-8") as f:
        json.dump(json_parse, f, ensure_ascii=False, separators=(",", ":"), indent=4)


if __name__ == "__main__":
    genes = Path(sys.argv[1])
    features = Path(sys.argv[2])
    cluster = Path(sys.argv[3])
    sample_name = sys.argv[4]
    parse_gecco(genes, features, cluster, sample_name)
