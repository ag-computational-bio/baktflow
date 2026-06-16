#!/usr/bin/env python3

import os
import json
import polars as pl
from pathlib import Path
from datetime import datetime
import gzip
import sys

def parse_ectyper(result_dir:str, sample_name:str):

    json_parse = {
        "meta_data": {
            "version": "baktflow 0.1.0", # version command, env files
            "module": "ectyper",
            "date": None,
            "sample": sample_name
        },
        "data": None
    }

    path = Path(result_dir)
    date  = datetime.fromtimestamp(os.path.getctime(path))
    json_parse["meta_data"]["date"] = str(date).split()[0]


    df = pl.read_csv(result_dir,
                     separator="\t",
                     new_columns=["name", "species", "species_mash_ratio", "species_mash_distance", "species_mash_top_if",
                              "o-type", "h-type", "serotype", "qc", "evidence", "gene_scores", "allele_keys", "gene_identities",
                              "gene_coverages", "gene_contig_names", "gene_ranges", "gene_lengths", "database_version",
                              "warnings", "pathotype", "pathotype_counts", "pathotype_genes", "pathotype_gene_names",
                              "pathotype_accessions", "pathotype_allele_ids", "pathotype_identities", "pathotype_coverages",
                              "pathotype_gene_length_ratios", "pathotype_rule_ids", "pathotype_gene_counts", "patho_database_version",
                              "stx_subtypes", "stx_accessions", "stx_allele_iss", "stx_allele_names", "stx_identities",
                              "stx_coverages", "stx_lengths", "stx_contig_sames", "stx_coordinates"])


    json_parse["data"] = df.to_dict(as_series=False)

    with gzip.open(f"{sample_name}.json.gz", "wt", encoding="utf-8") as f:
        json.dump(json_parse, f, ensure_ascii=False, separators=(",", ":"), indent=4)


if __name__ == "__main__":
    result_dir = Path(sys.argv[1])
    sample_name = sys.argv[2]
    parse_ectyper(result_dir, sample_name)