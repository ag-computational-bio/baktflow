#!/usr/bin/env python3

from Bio import SeqIO
import os
import json
import sys
from pathlib import Path
from datetime import datetime
import gzip

from utils import get_version

__version__ = get_version()

from baktflow import __version__


def assembly_stats(fasta_file: str):

    _, file_extension = os.path.splitext(str(fasta_file))

    opener = gzip.open if file_extension == ".gz" else open
    fmt = "fastq" if file_extension == ".gz" else "fasta"

    stats_single_sequences = []
    lengths = []

    count_n = 0
    count_c = 0
    count_g = 0
    total_length = 0
    number_sequences = 0

    with opener(fasta_file, "rt") as handle:
        for rec in SeqIO.parse(handle, fmt):
            seq = str(rec.seq)
            length = len(seq)

            n = seq.count("N")
            c = seq.count("C")
            g = seq.count("G")

            stats_single_sequences.append({
                "id": rec.id,
                "n": n,
                "gc_content": round((g + c) / length * 100, 2),
                "length": length,
                "seq": seq,
            })

            lengths.append(length)

            number_sequences += 1
            count_n += n
            count_c += c
            count_g += g
            total_length += length

    gc_content = round((count_g + count_c) / total_length * 100, 2)

    return number_sequences, stats_single_sequences, lengths, gc_content, count_n,



def calculate_n50(lengths:list):
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



def calculate_n90(lengths:list):
    """
       This method calculates the n90 value for an assembly based on the length of all contigs

       :param lengths: List of all contig lengths
       :return: N90 value
       """
    lengths_sorted = sorted(lengths, reverse=True)
    total = sum(lengths_sorted)
    cumulative = 0

    target = total  * (90 / 100)

    for length in lengths_sorted:
        cumulative += length
        if cumulative >= target:
            return length

    return None



def parse_assembly(result_dir:str, sample_name:str, module_name:str):
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
        "sequences": stats_single_sequences
    }

    with gzip.open(f"{sample_name}.json.gz", "wt", encoding="utf-8") as f:
        json.dump(json_parse, f, ensure_ascii=False, separators=(",", ":"), indent=4)


if __name__ == "__main__":
    result_dir = Path(sys.argv[1])
    sample_name = sys.argv[2]
    module_name = sys.argv[3]
    parse_assembly(result_dir, sample_name, module_name)
