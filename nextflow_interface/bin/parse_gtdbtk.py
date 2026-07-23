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


def parse_gtdbtk(result_dir: str, sample_name: str):
    json_parse = {
        "meta_data": {
            "version": __version__,
            "module": "gtdbtk",
            "date": None,
            "sample": sample_name
        },
        "data": None
    }

    path = Path(result_dir)
    date = datetime.fromtimestamp(os.path.getctime(path))
    json_parse["meta_data"]["date"] = str(date).split()[0]

    columns = ["user_genome", "classification", "closest_genome_reference", "closest_genome_reference_radius",
               "closest_genome_taxonomy", "closest_genome_ani", "closest_genome_af",
               "closest_placement_reference", "closest_placement_radius", "closest_placement_taxonomy",
               "closest_placement_ani",
               "closest_placement_af", "pplacer_taxonomy", "classification_method", "note",
               "other_related_references", "msa_percent", "translation_table", "red_value", "warnings"]

    try:
        df = pl.read_csv(
            result_dir,
            separator="\t",
            new_columns=columns
        )
    except pl.exceptions.NoDataError:
        df = pl.DataFrame(schema=columns)

    json_parse["data"] = df.to_dict(as_series=False)

    with gzip.open(f"{sample_name}.json.gz", "wt", encoding="utf-8") as f:
        json.dump(json_parse, f, ensure_ascii=False, separators=(",", ":"), indent=4)


if __name__ == "__main__":
    result_dir = Path(sys.argv[1])
    sample_name = sys.argv[2]
    parse_gtdbtk(result_dir, sample_name)
