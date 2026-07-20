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


def parse_referenceseeker(result_dir, sample_name):

    json_parse = {
        "meta_data": {
            "version": __version__,
            "module": "referenceseeker",
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
                     new_columns=["id", "mash_distance", "qr_ani", "qr_con_dna", "rq_ani", "rq_con_dna", "taxonomy_id",
                              "assembly_status", "organism"])


    json_parse["data"] = df.to_dict(as_series=False)


    with gzip.open(f"{sample_name}.json.gz", "wt", encoding="utf-8") as f:
        json.dump(json_parse, f, ensure_ascii=False, separators=(",", ":"), indent=4)



if __name__ == "__main__":
    result_dir = Path(sys.argv[1])
    sample_name = sys.argv[2]
    parse_referenceseeker(result_dir, sample_name)
