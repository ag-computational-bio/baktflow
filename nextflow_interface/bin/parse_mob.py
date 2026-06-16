#!/usr/bin/env python3

import os
import json
import sys
import polars as pl
from pathlib import Path
from datetime import datetime
import gzip


def parse_mob(result_dir:str, sample_name:str):

    json_parse = {
        "meta_data": {
            "version": "baktflow 0.1.0", # version command, env files
            "module": "diamond",
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
                     new_columns=["sample_id", "molecule_type", "primary_cluster_id", "secondary_cluster_id", "contig_id",
                                  "size", "gc", "md5", "mge_id", "mge_acs", "mge_type", "mge_subtype", "mge_length",
                                  "mge_start", "mge_end", "contig_start", "contig_end", "length", "sstrand", "qcovhsp",
                                  "pident", "evalue", "bitscore"])


    json_parse["data"] = df.to_dict(as_series=False)


    with gzip.open(f"results/{sample_name}.json.gz", "wt", encoding="utf-8") as f:
        json.dump(json_parse, f, ensure_ascii=False, separators=(",", ":"), indent=4)



if __name__ == "__main__":
    result_dir = Path(sys.argv[1])
    sample_name = sys.argv[2]
    parse_mob(result_dir, sample_name)