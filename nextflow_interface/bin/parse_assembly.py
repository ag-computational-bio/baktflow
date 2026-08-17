#!/usr/bin/env python3

import json
import os
import sys
from datetime import datetime
from pathlib import Path

from Bio import SeqIO
from versions import get_module_tool_versions
from xopen import xopen


def assembly_stats(fasta_file: str | Path) -> tuple[int, list[dict[str, str | int | float]], list[int], float, int]:
    fmt = "fastq" if str(fasta_file).rstrip(".gz").endswith("fastq") else "fasta"

    stats_single_sequences: list[dict[str, str | int | float]] = []
    lengths: list[int] = []

    count_n: int = 0
    count_c: int = 0
    count_g: int = 0
    total_length: int = 0
    number_sequences: int = 0

    with xopen(fasta_file, "rt") as handle:
        for rec in SeqIO.parse(handle, fmt):
            seq: str = str(rec.seq)
            length: int = len(seq)

            n: int = seq.count("N")
            c: int = seq.count("C")
            g: int = seq.count("G")

            stats_single_sequences.append(
                {
                    "id": rec.id,
                    "n": n,
                    "gc_content": round((g + c) / length * 100, 2),
                    "length": length,
                    "seq": seq,
                }
            )

            lengths.append(length)

            number_sequences += 1
            count_n += n
            count_c += c
            count_g += g
            total_length += length

    gc_content: float = round((count_g + count_c) / total_length * 100, 2)

    return (
        number_sequences,
        stats_single_sequences,
        lengths,
        gc_content,
        count_n,
    )


def calculate_n50(lengths: list[int]) -> int:
    """
    This method calculates the n50 value for an assembly based on the length of all contigs

    :param lengths: List of all contig lengths
    :return: N50 value
    """

    lengths_sorted: list[int] = sorted(lengths, reverse=True)
    total: int = sum(lengths_sorted)
    cumulative = 0

    for length in lengths_sorted:
        cumulative += length
        if cumulative >= total / 2:
            return length

    return 0


def calculate_n90(lengths: list[int]) -> int:
    """
    This method calculates the n90 value for an assembly based on the length of all contigs

    :param lengths: List of all contig lengths
    :return: N90 value
    """
    lengths_sorted: list[int] = sorted(lengths, reverse=True)
    total: int = sum(lengths_sorted)
    cumulative = 0

    target = total * (90 / 100)

    for length in lengths_sorted:
        cumulative += length
        if cumulative >= target:
            return length

    return 0


def parse_assembly(result_dir: Path, sample_name: str, module_name: str):
    """
    This method creates a JSON file containing all important information regarding the assembly

    :param result_dir: Path where the results are stored (string)
    :param sample_name: Sample ID (string)
    :param module_name: Name of module that was  used to create the assembly (string)
    :return: None
    """
    date: str = str(datetime.fromtimestamp(os.path.getctime(Path(result_dir)))).split()[0]

    number_sequences, stats_single_sequences, lengths, gc_content, count_n = assembly_stats(result_dir)
    n50: int = calculate_n50(lengths)
    n90: int = calculate_n90(lengths)

    data = {
        "n50": n50,
        "n90": n90,
        "n": count_n,
        "gc_content": gc_content,
        "number_sequences": number_sequences,
        "sequences": stats_single_sequences,
    }

    json_parse = {
        "meta_data": {"version": get_module_tool_versions(module_name), "module": module_name, "date": date,
                      "sample": sample_name},
        "data": data,
    }

    with xopen(f"report-{sample_name}.json.gz", "wt", compresslevel=9) as f:
        json.dump(json_parse, f, ensure_ascii=False, separators=(",", ":"), indent=4)


if __name__ == "__main__":
    result_dir = Path(sys.argv[1])
    sample_name = sys.argv[2]
    module_name = sys.argv[3]
    parse_assembly(result_dir, sample_name, module_name)
