#!/usr/bin/env python3

import argparse
import json
import os
import subprocess as sp
from pathlib import Path

import yaml
from packaging.version import Version


def parse_arguments():
    parser = argparse.ArgumentParser(description="Search for updates for environment yaml files.")
    parser.add_argument("--input", type=str, required=True, help="Path to the modules folder.")
    parser.add_argument("--conda", type=str, default="micromamba", help="Conda implementation [mamba]")
    return parser.parse_args()


def split_dependency_description(description: str) -> tuple[str, str]:
    version_handlers: tuple[str, str, str, str, str, str] = ("==", "<=", ">=", "=", "<", ">")
    for handler in version_handlers:
        if handler in description:
            desc = description.split(handler)
            return desc[0], desc[1]
    return description, ""


def main():
    args = parse_arguments()
    modules: list[Path] = [Path(str(x[0])) for x in os.walk(args.input)][1:]

    environment_definitions: dict[str, dict[str, str]] = {}

    for module in modules:
        env_path: Path = module.joinpath("environment.yaml")
        try:
            with open(env_path) as file:
                env_def = yaml.safe_load(file)
        except FileExistsError or FileNotFoundError or yaml.YAMLError as e:
            raise e

        environment_definitions[env_def["name"]] = {}
        for dep in env_def["dependencies"]:
            tool, version = split_dependency_description(dep)
            environment_definitions[env_def["name"]].setdefault(tool, version)

    all_deps: list[str] = sorted(list(set([dep for deps in environment_definitions.values() for dep in deps.keys()])))
    # print(all_deps)
    # print(environment_definitions)

    for environment, deps in environment_definitions.items():
        for dep, version in deps.items():
            cmd: list[str] = [args.conda, "search", "--json", f"{dep}>{version}"]
            conda_search = sp.run(cmd, encoding="utf-8", stdout=sp.PIPE)
            conda_search_out = json.loads(conda_search.stdout)
            if conda_search_out["result"]["status"] == "OK":
                if len(conda_search_out["result"]["pkgs"]) > 0:
                    if Version(conda_search_out["result"]["pkgs"][0]["version"]) > Version(version):
                        print(
                            f"Env: {environment}, package: {dep}\n\tCurrent:\t{version}\n\tNew:\t{conda_search_out['result']['pkgs'][0]['version']}"
                        )
                    # for x in conda_search_out["result"]["pkgs"]:
                    #     print(x["version"])
                    #     exit()
            else:
                raise Exception(f"Did not recive a valid conda serach output:\n{conda_search_out}")
            # print(conda_search_out)


if __name__ == "__main__":
    main()
