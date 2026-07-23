#!/usr/bin/env python3

import argparse
import concurrent.futures as cf
import os
import re
import shutil
import subprocess
import time
import zipfile
from urllib.error import URLError
from urllib.request import urlopen, urlretrieve

import requests

BASE_URL = "https://www.cgmlst.org/ncs"
SCHEMA_LIST_URL = f"{BASE_URL}/"


def fetch_schema_list() -> list[dict[str, str | list[str]]]:

    with urlopen(SCHEMA_LIST_URL, timeout=30) as response:
        html = response.read().decode("utf-8")

    schema_pattern = r"/ncs/schema/([A-Za-z0-9_]+)/"
    organism_pattern = r">([A-Z]{1}[a-z]+\s[A-Za-z0-9_/\. \(\)]+)</"
    schema_matches = re.findall(schema_pattern, html)
    organism_matches = re.findall(organism_pattern, html)
    schema_list: list[str] = list(dict.fromkeys(schema_matches))
    organism_list: list[str] = list(dict.fromkeys(organism_matches))

    spp = [o.split()[0] for o in organism_list if "spp." in o]
    schemata: list[dict[str, str | list[str]]] = []
    for schema, organism in zip(schema_list, organism_list[2:-2]):
        if schema.endswith("_complex"):
            organisms = [f"{organism.split('/')[0].split()[0]} {s}" for s in organism.split()[1].split("/")]
        elif schema.endswith("_fli") or schema.endswith("_rki"):
            organisms = [" ".join(organism.split()[:2])]
        elif schema in spp:
            organisms = [organism.rstrip("cgMLST").strip()]
        else:
            organisms = [organism]
        schemata.append({"schema": schema, "organisms": organisms})

    # j: int = 0
    # for i, organism_short in enumerate(schema_list):
    #     # TODO nach Koxytoca_complex funktioniertr es nicht mehr
    #     # print(organism_short)
    #     if organism_short.endswith("_complex"):
    #         while j < len(organism_list):
    #             tmp = organism_list[j].split("/")[0].split()
    #             short = tmp[0][0] + tmp[1]
    #             if organism_short.rstrip("_complex") == short:
    #                 organisms = [f"{tmp[0]} {s}" for s in organism_list[j].split()[1].split("/")]
    #                 schemata.append({"schema": organism_short, "organisms": organisms})
    #                 break
    #             j += 1
    #
    #     elif organism_short.endswith("_fli") or organism_short.endswith("_rki"):
    #         while j < len(organism_list):
    #             tmp = organism_list[j].split()
    #             short = tmp[0][0] + tmp[1]
    #             if organism_short.split("_")[0] == short and f"({organism_short.split('_')[1]})" == tmp[2].lower():
    #                 schemata.append({"schema": organism_short, "organisms": [" ".join(tmp[:2])]})
    #                 break
    #             j += 1
    #     elif organism_short in spp:
    #         while j < len(organism_list):
    #             if organism_short == organism_list[j].split()[0]:
    #                 schemata.append(
    #                     {"schema": organism_short, "organisms": [organism_list[j].rstrip("cgMLST").strip()]}
    #                 )
    #                 break
    #             j += 1
    #     else:
    #         while j < len(organism_list):
    #             tmp = organism_list[j].split()
    #             short = tmp[0][0] + tmp[1]
    #             if organism_short == short:
    #                 schemata.append({"schema": organism_short, "organisms": [organism_list[j]]})
    #                 break
    #             j += 1
    #
    #     j += 1

    # print(len(schema_list), schema_list)
    # print(len(organism_list), organism_list)
    # print(len(schemata), schemata)
    # pprint(schema_matches)
    # pprint(schemata)

    return schemata


def resolve_schema_id(schema_name):
    url = f"{BASE_URL}/schema/{schema_name}/"
    try:
        with urlopen(url, timeout=30) as response:
            schema_url = response.url
    except URLError as e:
        raise e

    match = re.search(r"/schema/(\d+)/", schema_url)

    if match:
        return match.group(1)
    else:
        return schema_name


def download_schema(schemata: dict[str, str | list[str]], outdir="chewBBACA", delay=1.5) -> str:
    print(f"\t{schemata['schema']}")
    schema_id = resolve_schema_id(schemata["schema"])
    if schema_id is None:
        raise Exception(f"Could not resolve schema: {schemata}")

    download_url = f"{BASE_URL}/schema/{schema_id}/alleles/"

    schema_dir = os.path.join(outdir, f"{schemata['organisms'][0].replace(' ', '_').rstrip('.')}RAW")
    os.makedirs(schema_dir, exist_ok=True)
    zip_path = os.path.join(outdir, f"{schemata['schema']}.zip")

    try:
        request = requests.get(download_url, timeout=30, stream=True)
        with open(zip_path, "wb") as fh:
            for chunk in request.iter_content(4 * 1024 * 1024):
                fh.write(chunk)
    except URLError or requests.exceptions.ReadTimeout as e:
        print(e)
        time.sleep(30)
        urlretrieve(download_url, zip_path)

    try:
        with zipfile.ZipFile(zip_path, "r") as zf:
            zf.extractall(str(schema_dir))
    except zipfile.BadZipFile as e:
        raise e

    if len(schemata["organisms"]) > 1:
        for organism in schemata["organisms"][1:]:
            os.symlink(schemata["organisms"][0].replace(" ", "_"), os.path.join(outdir, organism.replace(" ", "_")))

    os.remove(zip_path)
    time.sleep(delay)
    return str(schema_dir)


def prep_schema(schema_dir: str, threads: int = 1):
    print(f"\t{schema_dir.rstrip('/').split('/')[-1]}".rstrip("RAW"))
    prepped_dir = schema_dir.rstrip("/").rstrip("RAW")
    cmd = ["chewBBACA.py", "PrepExternalSchema", "-g", schema_dir, "-o", prepped_dir, "--cpu", str(threads)]
    subprocess.run(cmd)

    shutil.rmtree(schema_dir)
    # os.renames(prepped_dir, schema_dir)
    return prepped_dir


def parse_arguments():
    parser = argparse.ArgumentParser(description="Download chewbbaca databases from cgMLST.")
    parser.add_argument("--threads", type=int, default=8, help="Number of threads")
    return parser.parse_args()


def main():
    args = parse_arguments()
    targets = fetch_schema_list()
    os.makedirs("chewBBACA", exist_ok=True)

    print("Downloading:")
    schema_dirs = [download_schema(schema) for schema in targets]

    print("Preparing:")
    # for schema_dir in schema_dirs:
    #     prep_schema(schema_dir)
    with cf.ProcessPoolExecutor(max_workers=args.threads) as ppe:
        ppe.map(prep_schema, schema_dirs)

    # Link prepped tables for linked directories
    for schemata in targets:
        if len(schemata["organisms"]) > 1:
            for organism in schemata["organisms"][1:]:
                for suffix in (
                    "_invalid_alleles.txt",
                    "_invalid_loci.txt",
                    "_summary_stats.tsv",
                ):
                    prepped_dir = organism.replace(" ", "_") + suffix
                    os.symlink(
                        schemata["organisms"][0].replace(" ", "_") + suffix,
                        os.path.join("chewBBACA", prepped_dir),
                    )


if __name__ == "__main__":
    main()