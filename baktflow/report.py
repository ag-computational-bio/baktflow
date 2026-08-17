import os
from datetime import datetime
from pathlib import Path

import pysimdjson
from xopen import xopen

from baktflow import __version__
from versions import get_module_tool_versions


# TODO parse version number from toml file
# TODO parse tool version numbers from yaml env files

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


def parse_json(json_file: Path, module_name: str, sample_id: str):
    with xopen(json_file, "r") as file:
        data = pysimdjson.load(file)

    date: str = str(datetime.fromtimestamp(os.path.getctime(json_file))).split()[0]
    json_parse = {
        "meta_data": {"version": get_module_tool_versions(module_name), "module": module_name, "date": date,
                      "sample": sample_id},
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

    for file in path_json_files:
        file = Path(file)

        if file.name.startswith("report-"):
            with xopen(file, "rt", encoding="utf-8") as f:
                json_files.append(pysimdjson.load(f))
        else:
            relative_output = file.relative_to(output_dir)
            module_name = relative_output.parent.name

            parsed = parse_json(json_file=file, module_name=module_name, sample_id=sample_id)
            json_files.append(parsed)

    with xopen(f"{output_dir}/{sample_id}.json.gz", "wt", encoding="utf-8", compresslevel=9) as f:
        pysimdjson.dump(json_files, f, ensure_ascii=False, indent=4)


def aio_create_aggregated_json(output: Path, sample: str):
    jsons = check_output(output_dir=f"{output}/{sample}")
    create_aggregated_json(path_json_files=jsons, output_dir=f"{output}/{sample}", sample_id=sample)
