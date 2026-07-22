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


def read_tsv_safe(path):
    try:
        df = pl.read_csv(path, separator="\t")
        df.columns = [col.lower() for col in df.columns]
    except pl.exceptions.NoDataError:
        df = pl.DataFrame()
    return df


def parse_chewbbaca(cds_coordinates: str, loci_summary_stats: str, contigs_results: str, alleles_results: str,
                    paralogous: str, sample_name: str):
    json_parse = {
        "meta_data": {
            "version": __version__,
            "module": "chewbbaca",
            "date": None,
            "sample": sample_name
        },
        "data": {}
    }
    path_genes = Path(cds_coordinates)
    date = datetime.fromtimestamp(os.path.getctime(path_genes))
    json_parse["meta_data"]["date"] = str(date).split()[0]

    df_cds_coordinates = read_tsv_safe(cds_coordinates)
    df_loci = read_tsv_safe(loci_summary_stats)
    df_contig = read_tsv_safe(contigs_results)
    df_alleles = read_tsv_safe(alleles_results)
    df_paralogous = read_tsv_safe(paralogous)

    json_parse["data"].update({
        "cds_coordinates": df_cds_coordinates.to_dict(as_series=False),
        "loci": df_loci.to_dict(as_series=False),
        "contig": df_contig.to_dict(as_series=False),
        "alleles": df_alleles.to_dict(as_series=False),
        "paralogous": df_paralogous.to_dict(as_series=False)
    })

    with gzip.open(f"{sample_name}.json.gz", "wt", encoding="utf-8") as f:
        json.dump(json_parse, f, ensure_ascii=False, separators=(",", ":"), indent=4)
