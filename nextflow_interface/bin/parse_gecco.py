#!/usr/bin/env python3

import json
import os
import sys
from datetime import datetime
from pathlib import Path

import polars as pl
from versions import get_module_tool_versions
from xopen import xopen


def parse_gecco(genes: str, features: str, cluster: str, sample_name: str):
    date: str = str(datetime.fromtimestamp(os.path.getctime(Path(genes)))).split()[0]

    columns_genes = ["sequence_id", "protein_id", "start", "end", "strand", "average_p", "max_p"]

    columns_features = [
        "sequence_id",
        "protein_id",
        "start",
        "end",
        "strand",
        "domain",
        "hmm",
        "i_evalue",
        "p_value",
        "domain_start",
        "domain_end",
        "cluster_probability",
    ]

    columns_cluster = [
        "sequence_id",
        "cluster_id",
        "start",
        "end",
        "average_p",
        "max_p",
        "type",
        "alkaloid_probability",
        "nrp_probability",
        "polyketide_probability",
        "ripp_probability",
        "saccharide_probability",
        "terpene_probability",
        "proteins",
        "domains",
    ]

    df_genes = pl.DataFrame(schema=columns_genes)
    df_features = pl.DataFrame(schema=columns_features)
    df_cluster = pl.DataFrame(schema=columns_cluster)

    if genes is not None:
        try:
            df_genes = pl.read_csv(genes, separator="\t", new_columns=columns_genes)
        except pl.exceptions.NoDataError:
            pass

    if features is not None:
        try:
            df_features = pl.read_csv(features, separator="\t", new_columns=columns_features)
        except pl.exceptions.NoDataError:
            pass

    if cluster is not None:
        try:
            df_cluster = pl.read_csv(cluster, separator="\t", new_columns=columns_cluster)
        except pl.exceptions.NoDataError:
            pass

    data = (
        {
            "genes": df_genes.to_dict(as_series=False),
            "features": df_features.to_dict(as_series=False),
            "cluster": df_cluster.to_dict(as_series=False),
        }
    )

    json_parse = {
        "meta_data": {"version": get_module_tool_versions("gecco"), "module": "gecco", "date": date,
                      "sample": sample_name},
        "data": data,
    }

    with xopen(f"report-{sample_name}.json.gz", "wt", compresslevel=9) as f:
        json.dump(json_parse, f, ensure_ascii=False, separators=(",", ":"), indent=4)


if __name__ == "__main__":
    genes = sys.argv[1]
    features = sys.argv[2]
    clusters = sys.argv[3]
    sample_name = sys.argv[4]
    parse_gecco(genes, features, clusters, sample_name)
