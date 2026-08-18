#!/usr/bin/env python3

import json
import os
import sys
from datetime import datetime
from pathlib import Path

import polars as pl
from versions import get_module_tool_versions
from xopen import xopen


def parse_ectyper(result_dir: str | Path, sample_name: str):
    date: str = str(datetime.fromtimestamp(os.path.getctime(Path(result_dir)))).split()[0]

    columns = [
        "name",
        "species",
        "species_mash_ratio",
        "species_mash_distance",
        "species_mash_top_if",
        "o-type",
        "h-type",
        "serotype",
        "qc",
        "evidence",
        "gene_scores",
        "allele_keys",
        "gene_identities",
        "gene_coverages",
        "gene_contig_names",
        "gene_ranges",
        "gene_lengths",
        "database_version",
        "warnings",
        "pathotype",
        "pathotype_counts",
        "pathotype_genes",
        "pathotype_gene_names",
        "pathotype_accessions",
        "pathotype_allele_ids",
        "pathotype_identities",
        "pathotype_coverages",
        "pathotype_gene_length_ratios",
        "pathotype_rule_ids",
        "pathotype_gene_counts",
        "patho_database_version",
        "stx_subtypes",
        "stx_accessions",
        "stx_allele_iss",
        "stx_allele_names",
        "stx_identities",
        "stx_coverages",
        "stx_lengths",
        "stx_contig_sames",
        "stx_coordinates",
    ]

    try:
        df = pl.read_csv(result_dir, separator="\t", new_columns=columns)
    except pl.exceptions.NoDataError:
        df = pl.DataFrame(schema=columns)

    data = df.to_dict(as_series=False)

    json_parse = {
        "meta_data": {"version": get_module_tool_versions("ectyper"), "module": "ectyper", "date": date,
                      "sample": sample_name},
        "data": data,
    }

    with xopen(f"report-{sample_name}.json.gz", "wt", compresslevel=9) as f:
        json.dump(json_parse, f, ensure_ascii=False, separators=(",", ":"), indent=4)


if __name__ == "__main__":
    result_dir = Path(sys.argv[1])
    sample_name = sys.argv[2]
    parse_ectyper(result_dir, sample_name)
