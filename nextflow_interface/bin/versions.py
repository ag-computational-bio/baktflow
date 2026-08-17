#!/usr/bin/env python3

from pathlib import Path
import os
import yaml


def get_module_tool_versions(module: str) -> dict[str, str]:
    base_path: Path = Path(os.path.dirname(os.path.realpath(__file__)))
    module_env_path: Path = base_path.joinpath(f"../modules/{module}/environment.yaml")

    try:
        with open(module_env_path) as file:
            env_def = yaml.safe_load(file)
    except FileExistsError or FileNotFoundError or yaml.YAMLError as e:
        raise e

    environment_dependencies: dict[str, str] = {}
    for dep in env_def["dependencies"]:
        tool, version = split_dependency_description(dep)
        environment_dependencies.setdefault(tool, version)

    return environment_dependencies


def split_dependency_description(description: str) -> tuple[str, str]:
    for handler in ("==", "<=", ">=", "=", "<", ">"):
        if handler in description:
            desc = description.split(handler)
            return desc[0], desc[1]
    return description, ""
