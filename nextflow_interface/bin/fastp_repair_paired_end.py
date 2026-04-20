#!/usr/bin/env python3

from argparse import ArgumentParser
from pathlib import Path
from typing import Generator

from Bio.SeqIO.QualityIO import FastqGeneralIterator
from xopen import xopen


def parse_arguments():
    """Parse command-line arguments."""
    parser = ArgumentParser(
        description="FASTQ repair script: Fix paired end FASTQ files with mismatching read numbers."
    )
    parser.add_argument("--r1", type=str, help="R1 FASTQ file", required=True)
    parser.add_argument("--r2", type=str, help="R2 FASTQ file", required=True)
    parser.add_argument("--output", type=str, default="./", help="Path to output directory [./]")
    parser.add_argument("--prefix", type=str, help="File prefix", required=True)
    parser.add_argument("--threads", type=int, default=4, help="Threads")
    return parser.parse_args()


def parse_fastq(file_path: Path) -> Generator[tuple[str, str, str], None, None]:
    """
    Parse a fasta file and yield the headers and sequences.
    :param file_path:
    :return: (header, sequence)
    """
    with xopen(file_path) as f:
        for header, seq, qual in FastqGeneralIterator(f):
            yield header, seq, qual


def main():
    args = parse_arguments()

    path_r1: Path = Path(args.r1)
    path_r2: Path = Path(args.r2)
    path_out: Path = Path(args.output)
    path_r1_out: Path = Path(path_out.joinpath(f"{args.prefix}_R1_cleaned.fastq.gz"))
    path_r2_out: Path = Path(path_out.joinpath(f"{args.prefix}_R2_cleaned.fastq.gz"))
    path_se_out: Path = Path(path_out.joinpath("SE_cleaned.fastq.gz"))

    r1_reads: dict[str, tuple[str, str]] = {header.split()[0]: (seq, qual) for header, seq, qual in
                                            parse_fastq(path_r1)}
    r2_reads: dict[str, tuple[str, str]] = {header.split()[0]: (seq, qual) for header, seq, qual in
                                            parse_fastq(path_r2)}
    r1_headers: set[str] = set(r1_reads.keys())
    r2_headers: set[str] = set(r2_reads.keys())
    both_headers: list[str] = sorted(list(r1_headers.intersection(r2_headers)))
    single_headers: list[str] = sorted(list(r1_headers.symmetric_difference(r2_headers)))
    assert sum((len(r1_headers), len(r2_headers))) / 2 == sum((len(both_headers),
                                                               len(single_headers))), f"{sum((len(r1_headers), len(r2_headers)))}, {len(both_headers)}, {len(single_headers)}"
    print(
        f"Reads\n\tR1: {len(r1_headers)}\n\tR2: {len(r2_headers)}\nIdentical headers: {len(both_headers)}\nSingletons:{len(single_headers)}")

    path_out.mkdir(parents=True, exist_ok=True)
    with (
        xopen(path_r1_out, "w", compresslevel=9, threads=args.threads) as f_r1_out,
        xopen(path_r2_out, "w", compresslevel=9, threads=args.threads) as f_r2_out,
    ):
        for header in both_headers:
            r1_seq, r1_qual = r1_reads[header]
            r2_seq, r2_qual = r2_reads[header]
            f_r1_out.write(f"@{header}\n{r1_seq}\n+\n{r1_qual}\n")
            f_r2_out.write(f"@{header}\n{r2_seq}\n+\n{r2_qual}\n")

    if len(single_headers) > 0:
        with xopen(path_se_out, "w", compresslevel=9, threads=args.threads) as f_se_out:
            for header in single_headers:
                se_seq, se_qual = r1_reads[header] if header in r1_reads else r2_reads[header]
                f_se_out.write(f"@{header}\n{se_seq}\n+\n{se_qual}\n")


if __name__ == "__main__":
    main()
