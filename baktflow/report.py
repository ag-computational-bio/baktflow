#!/usr/bin/env python3

import os
from pathlib import Path
import warnings
import json
from datetime import datetime
import gzip

# TODO: HTML/PDF report erstellen

def check_output(output_dir):

    results_dirs = [item for item in Path(output_dir).iterdir()if item.is_dir() and not item.name.startswith(".")]

    paths_json_files = None

    for result_path in results_dirs:
        paths_json_files = list(result_path.rglob("*.json")) + list(result_path.rglob("*.json.gz"))

        if not paths_json_files:
            warnings.warn(f"No json result found in: {result_path}")

    return paths_json_files


def normalize_keys(obj):
    if isinstance(obj, dict):
        return {
            key.lower().replace(" ", "_"): normalize_keys(value)
            for key, value in obj.items()
        }
    elif isinstance(obj, list):
        return [normalize_keys(item) for item in obj]
    return obj


def parse_json(json_file, module_name:str, sample_id):

    with open(json_file, 'r') as file:
        data = json.load(file)

    json_parse = {
        "meta_data": {
            "version": "baktflow 0.1.0", # version command, env files
            "module": module_name,
            "date": None,
            "sample": sample_id
        },
        "data": None
    }

    date  = datetime.fromtimestamp(os.path.getctime(json_file))
    json_parse["meta_data"]["date"] = str(date).split()[0]

    json_parse["data"] = normalize_keys(data)

    return json_parse


def create_aggregated_json(path_json_files: list, output_dir: str, sample_id: str):

    json_files = []

    for file in path_json_files:
        file = Path(file)

        if file.suffix == ".gz":
            with gzip.open(file, "rt", encoding="utf-8") as f:
                json_files.append(json.load(f))
        else:

            relative_output = file.relative_to(output_dir)
            module_name = relative_output.parts[1]

            parsed = parse_json(
                json_file=file,
                module_name=module_name,
                sample_id=sample_id
            )
            json_files.append(parsed)


    with gzip.open(f"{output_dir}/{sample_id}.json.gz", "wt", encoding="utf-8") as f:
        json.dump(json_files, f, ensure_ascii=False, indent=4)