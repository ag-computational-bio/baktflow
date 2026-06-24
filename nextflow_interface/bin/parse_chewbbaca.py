#!/usr/bin/env python3

import os
import json
import polars as pl
from pathlib import Path
from datetime import datetime
import gzip
import sys


def parse_chewbbaca(cds_coordinates:str, loci_summary_stats:str, contigs_results:str, alleles_results:str, paralogous:str, sample_name:str):

    json_parse = {
        "meta_data": {
            "version": "baktflow 0.1.0", # version command, env files
            "module": "gecco",
            "date": None,
            "sample": sample_name
        },
        "data": {}
    }
    path_genes = Path(cds_coordinates)
    date  = datetime.fromtimestamp(os.path.getctime(path_genes))
    json_parse["meta_data"]["date"] = str(date).split()[0]

    df_cds_coordinates = pl.read_csv(cds_coordinates, separator="\t")
    df_cds_coordinates.columns = [col.lower() for col in df_cds_coordinates.columns]

    df_loci = pl.read_csv(loci_summary_stats, separator="\t")
    df_loci.columns = [col.lower() for col in df_loci.columns]

    df_contig = pl.read_csv(contigs_results, separator="\t")
    df_contig.column = [col.lower for col in df_contig.columns]

    df_alleles = pl.read_csv(alleles_results, separator="\t")
    df_alleles.columns = [col.lower() for col in df_alleles.columns]

    df_paralogous = pl.read_csv(paralogous, separator="\t")
    df_paralogous.columns = [col.lower() for col in df_paralogous.columns]

    json_parse["data"].update({
        "cds_coordinates": df_cds_coordinates.to_dict(as_series=False),
        "loci": df_loci.to_dict(as_series=False),
        "contig": df_contig.to_dict(as_series=False),
        "alleles": df_alleles.to_dict(as_series=False),
        "paralogous": df_paralogous.to_dict(as_series=False)
    })

    with gzip.open(f"{sample_name}.json.gz", "wt", encoding="utf-8") as f:
        json.dump(json_parse, f, ensure_ascii=False, separators=(",", ":"), indent=4)
