import os
from datetime import datetime
from pathlib import Path

import json
from xopen import xopen

from baktflow import __version__
from baktflow.versions import get_module_tool_versions


# TODO: HTML/PDF report erstellen


def check_output(output_dir: str | Path) -> list[Path]:
    skip_dirs: list[str] = ["ska", "bandage"]

    results_dirs: list[Path] = [
        item
        for item in Path(output_dir).iterdir()
        if item.is_dir() and not item.name.startswith(".") and item.name not in skip_dirs
    ]

    all_json_files: list[Path] = []

    for result_path in results_dirs:
        paths_json_files: list[Path] = list(result_path.rglob("*.json")) + list(result_path.rglob("*.json.gz"))

        if not paths_json_files:
            # warnings.warn(f"No json result found in: {result_path}")
            pass
        else:
            all_json_files.extend(paths_json_files)

    return all_json_files


def normalize_keys(obj):
    if isinstance(obj, dict):
        return {key.lower().replace(" ", "_"): normalize_keys(value) for key, value in obj.items()}
    elif isinstance(obj, list):
        return [normalize_keys(item) for item in obj]
    return obj


def parse_json(json_file: Path | list[Path], module_name: str, sample_id: str):
    if isinstance(json_file, Path):
        json_files = [json_file]
    else:
        json_files = json_file

    data = []

    for file_path in json_files:
        with xopen(file_path, "r") as file:
            data.append(json.load(file))

    date: str = str(datetime.fromtimestamp(json_files[0].stat().st_ctime)).split()[0]

    json_parse = {
        "meta_data": {
            "version": get_module_tool_versions(module_name),
            "module": module_name,
            "date": date,
            "sample": sample_id,
        },
        "data": normalize_keys(data),
    }

    return json_parse


def create_aggregated_json(path_json_files: list, output_dir: str | Path, sample_id: str):
    json_files = [
        {
            "meta_data": {
                "module": "baktflow",
                "version": {"baktflow": __version__},
                "date": str(datetime.today()).split()[0],
                "sample": sample_id,
            },
            "data": None,
        }
    ]
    json_sub_dirs = {}

    for file in path_json_files:
        file = Path(file)
        if file.name.startswith("report-"):
            with xopen(file, "rt") as f:
                json_files.append(json.load(f))
        else:
            relative_output = file.relative_to(output_dir)
            module_name = relative_output.parent.name

            dir_split = str(relative_output).split("/")
            if len(dir_split) < 3:
                parsed = parse_json(json_file=file, module_name=module_name, sample_id=sample_id)
            else:
                module_name = dir_split[0]
                json_sub_dirs[module_name] = json_sub_dirs.get(module_name, []) + [file]
            json_files.append(parsed)

    parsed = parse_json(json_file=list(json_sub_dirs.values())[0], module_name=str(next(iter(json_sub_dirs))), sample_id=sample_id)
    json_files.append(parsed)

    with xopen(f"{output_dir}/{sample_id}.json.gz", "wt", compresslevel=9) as f:
        json.dump(json_files, f, ensure_ascii=False, indent=4)


def aio_create_aggregated_json(output: Path, sample: str):
    jsons = check_output(output_dir=f"{output}/{sample}")
    create_aggregated_json(path_json_files=jsons, output_dir=f"{output}/{sample}", sample_id=sample)
