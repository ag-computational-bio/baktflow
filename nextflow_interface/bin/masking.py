#!/usr/bin/env python3

import sys

from Bio import SeqIO

threshold: int = int(sys.argv[1])  # 10
total_bases: int = 0
masked_bases: int = 0
total_records: int = 0

for record in SeqIO.parse(sys.stdin, "fastq"):
    total_records += 1

    corrected_seq_list: list[str] = []
    for i in range(len(record.seq)):
        total_bases += 1

        if record.letter_annotations["phred_quality"][i] > threshold:
            corrected_seq_list.append(record.seq[i].upper())
        else:
            corrected_seq_list.append("N")
            masked_bases += 1

    corrected_seq: str = "".join(corrected_seq_list)

    print(f">{record.id}\n{corrected_seq}\n")
