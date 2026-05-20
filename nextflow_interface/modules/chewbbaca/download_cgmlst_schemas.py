#!/usr/bin/env python3

import argparse
import os
import re
import shutil
import subprocess
import time
import zipfile
from urllib.request import urlopen, urlretrieve
from urllib.error import URLError

BASE_URL = "https://www.cgmlst.org/ncs"
SCHEMA_LIST_URL = f"{BASE_URL}/"

def fetch_schema_list():

    with urlopen(SCHEMA_LIST_URL, timeout=30) as response:
        html = response.read().decode("utf-8")

    pattern = r'/ncs/schema/([A-Za-z0-9_]+)/'
    matches = re.findall(pattern, html)

    return list(dict.fromkeys(matches))


def resolve_schema_id(schema_name):

    url = f"{BASE_URL}/schema/{schema_name}/"
    try:
        with urlopen(url, timeout=30) as response:
            schema_url = response.url
    except URLError as e:
        return None

    match = re.search(r'/schema/(\d+)/', schema_url)
    if match:
        return match.group(1)
    else:
        return schema_name


def download_schema(schema_name, outdir, delay=0.5):

    schema_id = resolve_schema_id(schema_name)
    if schema_id is None:
        return None

    download_url = f"{BASE_URL}/schema/{schema_id}/alleles/"

    schema_dir = os.path.join(outdir, schema_name)
    os.makedirs(schema_dir, exist_ok=True)
    zip_path = os.path.join(outdir, f"{schema_name}.zip")

    try:
        urlretrieve(download_url, zip_path)
    except URLError as e:
        return None

    try:
        with zipfile.ZipFile(zip_path, 'r') as zf:
            zf.extractall(schema_dir)
    except zipfile.BadZipFile as e:
        return None

    os.remove(zip_path)
    time.sleep(delay)
    return schema_dir


def prep_schema(schema_dir):

    prepped_dir = schema_dir.rstrip("/") + "_prepped"
    cmd = [
        "chewBBACA.py", "PrepExternalSchema",
        "-g", schema_dir,
        "-o", prepped_dir,
        "--cpu", "8"
    ]
    subprocess.run(cmd)

    shutil.rmtree(schema_dir)
    os.renames(prepped_dir, schema_dir)
    return prepped_dir


def main():
    targets = fetch_schema_list()
    os.makedirs("chewBBACA", exist_ok=True)

    for schema in targets:
        schema_dir = download_schema(schema, "chewBBACA")
        prep_schema(schema_dir)


if __name__ == "__main__":
    main()
