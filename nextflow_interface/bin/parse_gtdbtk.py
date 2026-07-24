#!/usr/bin/env python3

import gzip
import json
import os
import sys
from datetime import datetime
from pathlib import Path

import polars as pl

__version__ = "0.1.0"


def parse_gtdbtk(result_dir: str | Path, sample_name: str):
    json_parse = {
        "meta_data": {"version": __version__, "module": "gtdbtk", "date": None, "sample": sample_name},
        "data": None,
    }

    path = Path(result_dir)
    date = datetime.fromtimestamp(os.path.getctime(path))
    json_parse["meta_data"]["date"] = str(date).split()[0]

    columns = [
        "user_genome",
        "classification",
        "closest_genome_reference",
        "closest_genome_reference_radius",
        "closest_genome_taxonomy",
        "closest_genome_ani",
        "closest_genome_af",
        "closest_placement_reference",
        "closest_placement_radius",
        "closest_placement_taxonomy",
        "closest_placement_ani",
        "closest_placement_af",
        "pplacer_taxonomy",
        "classification_method",
        "note",
        "other_related_references",
        "msa_percent",
        "translation_table",
        "red_value",
        "warnings",
    ]

    try:
        df = pl.read_csv(result_dir, separator="\t", new_columns=columns)
    except pl.exceptions.NoDataError:
        df = pl.DataFrame(schema=columns)

    json_parse["data"] = df.to_dict(as_series=False)

    with gzip.open(f"{sample_name}.json.gz", "wt", encoding="utf-8") as f:
        json.dump(json_parse, f, ensure_ascii=False, separators=(",", ":"), indent=4)


if __name__ == "__main__":
    result_dir = Path(sys.argv[1])
    sample_name = sys.argv[2]
    parse_gtdbtk(result_dir, sample_name)
