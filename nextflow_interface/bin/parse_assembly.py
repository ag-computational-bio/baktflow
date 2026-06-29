#!/usr/bin/env python3

from Bio import SeqIO
import os
import json
import sys
from pathlib import Path
from datetime import datetime
import gzip


def assembly_stats(fasta_file:str):
    """
    This method determines basic stats values of a given assembly fasta file

    :param fasta_file: Path to where the assembly file is stored
    :return: number of all sequences (int), dictionary with sequence as key and length of the sequence as value,
    lengths of all sequences (list)
    """

    _, file_extension = os.path.splitext(fasta_file)

    if file_extension == ".gz":
        with gzip.open(fasta_file, "rt") as file:
            sequences = list(SeqIO.parse(file, "fastq"))
    else:
        sequences = list(SeqIO.parse(fasta_file, "fasta"))

    number_sequences = (len(sequences))

    seq_lengths = {rec.id: len(rec.seq) for rec in sequences}
    lengths = [len(rec.seq) for rec in sequences]

    return number_sequences, seq_lengths, lengths



def calculate_n50(lengths:list):
    """
    This method calculates the n50 value vor an assembly based on the length of all contigs

    :param lengths: List of all contig lengths
    :return: N50 value
    """

    lengths_sorted = sorted(lengths,reverse=True)

    total = sum(lengths_sorted)
    cumulative = 0

    for length in lengths_sorted:
        cumulative += length
        if cumulative >= total / 2:
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
        "meta_data": {
            "version": "baktflow 0.1.0", # version command, env files
            "module": module_name,
            "date": None,
            "sample": sample_name
        },
        "data": None
    }

    path = Path(result_dir)
    date  = datetime.fromtimestamp(os.path.getctime(path))
    json_parse["meta_data"]["date"] = str(date).split()[0]


    number_sequences, seq_lengths, lengths = assembly_stats(result_dir)
    n50 = calculate_n50(lengths)


    json_parse["data"] = {
        "n50": n50,
        "number_sequences": number_sequences,
        "seq_lengths": seq_lengths
    }

    with gzip.open(f"{sample_name}.json.gz", "wt", encoding="utf-8") as f:
        json.dump(json_parse, f, ensure_ascii=False, separators=(",", ":"), indent=4)


if __name__ == "__main__":
    result_dir = Path(sys.argv[1])
    sample_name = sys.argv[2]
    module_name = sys.argv[3]
    parse_assembly(result_dir, sample_name, module_name)
