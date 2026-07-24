#!/usr/bin/env python3

import gzip
import json
import os
import sys
from datetime import datetime
from pathlib import Path

import polars as pl
from utils import get_version

__version__ = get_version()


def read_tsv(path):
    try:
        df = pl.read_csv(path, separator="\t")
        df.columns = [col.lower() for col in df.columns]
    except pl.exceptions.NoDataError:
        df = pl.DataFrame()
    return df


def parse_chewbbaca(
    cds_coordinates: str | Path,
    loci_summary_stats: str | Path,
    contigs_results: str | Path,
    alleles_results: str | Path,
    paralogous: str | Path,
    sample_name: str,
):
    json_parse = {
        "meta_data": {"version": __version__, "module": "chewbbaca", "date": None, "sample": sample_name},
        "data": {},
    }
    path_genes = Path(cds_coordinates)
    date = datetime.fromtimestamp(os.path.getctime(path_genes))
    json_parse["meta_data"]["date"] = str(date).split()[0]

    df_cds_coordinates = read_tsv(cds_coordinates)
    df_loci = read_tsv(loci_summary_stats)
    df_contig = read_tsv(contigs_results)
    df_alleles = read_tsv(alleles_results)
    df_paralogous = read_tsv(paralogous)

    json_parse["data"].update(
        {
            "cds_coordinates": df_cds_coordinates.to_dict(as_series=False),
            "loci": df_loci.to_dict(as_series=False),
            "contig": df_contig.to_dict(as_series=False),
            "alleles": df_alleles.to_dict(as_series=False),
            "paralogous": df_paralogous.to_dict(as_series=False),
        }
    )

    with gzip.open(f"{sample_name}.json.gz", "wt", encoding="utf-8") as f:
        json.dump(json_parse, f, ensure_ascii=False, separators=(",", ":"), indent=4)


if __name__ == "__main__":
    cds_coordinates = Path(sys.argv[1])
    loci_summary_stats = Path(sys.argv[2])
    contigs_results = Path(sys.argv[3])
    alleles_results = Path(sys.argv[4])
    paralogous = Path(sys.argv[5])
    sample_name = sys.argv[6]
    parse_chewbbaca(cds_coordinates, loci_summary_stats, contigs_results, alleles_results, paralogous, sample_name)
