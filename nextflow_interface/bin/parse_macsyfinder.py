#!/usr/bin/env python3

import os
import json
import sys
import polars as pl
from pathlib import Path
from datetime import datetime
import gzip

def parse_macsyfinder(result_dir:str, sample_name:str, model_name:str):

    json_parse = {
        "meta_data": {
            "version": "baktflow 0.1.0", # version command, env files
            "module": "macsyfinder",
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
                     skip_rows=4,
                     new_columns=["replicon", "hit_id", "gene_name", "hit_pos", "model_fqn", "sys_id", "sys_loci", "locus_num",
                                  "sys_wholeness", "sys_score", "sys_occ", "hit_gene_ref", "hit_status", "hit_seq_len",
                                  "hit_i_eval", "hit_score", "hit_profile_cov", "hit_seq_cov", "hit_begin_match",
                                  "hit_end_match", "counterpart", "used_in"])

    json_parse["data"] = df.to_dict(as_series=False)

    with gzip.open(f"{model_name}/{sample_name}.json.gz", "wt", encoding="utf-8") as f:
        json.dump(json_parse, f, ensure_ascii=False, separators=(",", ":"), indent=4)


if __name__ == "__main__":
    result_dir = Path(sys.argv[1])
    sample_name = sys.argv[2]
    model_name = sys.argv[3]
    parse_macsyfinder(result_dir, sample_name, model_name)