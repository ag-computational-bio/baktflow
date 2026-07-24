#!/usr/bin/env python3

import gzip
import json
import os
import sys
from datetime import datetime
from pathlib import Path

from Bio import SeqIO
from utils import get_version

__version__ = get_version()


def assembly_stats(fasta_file: str | Path):
    """
    This method determines basic stats values of a given assembly fasta file

    :param fasta_file: Path to where the assembly file is stored
    :return: number of all sequences (int), dictionary with statistics for all sequences,
    lengths of all sequences (list), gc_content (float), count_n (int)
    """

    _, file_extension = os.path.splitext(str(fasta_file))

    if file_extension == ".gz":
        with gzip.open(fasta_file, "rt") as file:
            sequences = list(SeqIO.parse(file, "fastq"))
    else:
        sequences = list(SeqIO.parse(fasta_file, "fasta"))

    number_sequences = len(sequences)

    stats_single_sequences = []

    for rec in sequences:
        stats_single_sequences.append(
            {
                "id": rec.id,
                "n": rec.seq.count("N"),
                "gc_content": round((rec.seq.count("G") + rec.seq.count("C")) / len(rec.seq) * 100, 2),
                "length": len(rec.seq),
                "seq": str(rec.seq),
            }
        )

    lengths = [len(rec.seq) for rec in sequences]

    count_n = sum(rec.seq.count("N") for rec in sequences)
    count_c = sum(rec.seq.count("C") for rec in sequences)
    count_g = sum(rec.seq.count("G") for rec in sequences)

    total_length = sum(len(rec.seq) for rec in sequences)

    gc_content = round((count_g + count_c) / float(total_length) * 100, 2)

    return number_sequences, stats_single_sequences, lengths, gc_content, count_n


def calculate_n50(lengths: list):
    """
    This method calculates the n50 value for an assembly based on the length of all contigs

    :param lengths: List of all contig lengths
    :return: N50 value
    """

    lengths_sorted = sorted(lengths, reverse=True)
    total = sum(lengths_sorted)
    cumulative = 0

    for length in lengths_sorted:
        cumulative += length
        if cumulative >= total / 2:
            return length

    return None


def calculate_n90(lengths: list):
    """
    This method calculates the n90 value for an assembly based on the length of all contigs

    :param lengths: List of all contig lengths
    :return: N90 value
    """
    lengths_sorted = sorted(lengths, reverse=True)
    total = sum(lengths_sorted)
    cumulative = 0

    target = total * (90 / 100)

    for length in lengths_sorted:
        cumulative += length
        if cumulative >= target:
            return length

    return None


def parse_assembly(result_dir: str | Path, sample_name: str, module_name: str):
    """
    This method creates a JSON file containing all important information regarding the assembly

    :param result_dir: Path where the results are stored (string)
    :param sample_name: Sample ID (string)
    :param module_name: Name of module that was  used to create the assembly (string)
    :return: None
    """

    json_parse = {
        "meta_data": {"version": __version__, "module": module_name, "date": None, "sample": sample_name},
        "data": {},
    }

    path = Path(result_dir)
    date = datetime.fromtimestamp(os.path.getctime(path))
    json_parse["meta_data"]["date"] = str(date).split()[0]

    number_sequences, stats_single_sequences, lengths, gc_content, count_n = assembly_stats(result_dir)
    n50 = calculate_n50(lengths)
    n90 = calculate_n90(lengths)

    json_parse["data"] = {
        "n50": n50,
        "n90": n90,
        "n": count_n,
        "gc_content": gc_content,
        "number_sequences": number_sequences,
        "sequences": stats_single_sequences,
    }

    with gzip.open(f"{sample_name}.json.gz", "wt", encoding="utf-8") as f:
        json.dump(json_parse, f, ensure_ascii=False, separators=(",", ":"), indent=4)


if __name__ == "__main__":
    result_dir = Path(sys.argv[1])
    sample_name = sys.argv[2]
    module_name = sys.argv[3]
    parse_assembly(result_dir, sample_name, module_name)
