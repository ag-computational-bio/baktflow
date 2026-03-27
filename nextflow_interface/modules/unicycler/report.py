import argparse
import gzip
import json
import os

from Bio import SeqIO


# Function to calculate GC content of a sequence
def calculate_gc_content(sequence):
    g_count = sequence.count("G")
    c_count = sequence.count("C")
    total_bases = len(sequence)
    if total_bases == 0:
        return 0  # To handle empty sequences, though it shouldn't happen for FASTA files
    return (g_count + c_count) / total_bases * 100


# Function to parse the FASTA file (supporting .gz files)
def parse_fasta(fasta_file):
    contigs = {}
    if fasta_file.endswith(".gz"):
        with gzip.open(fasta_file, "rt") as f:  # Use 'rt' to open the file in text mode for .gz files
            for record in SeqIO.parse(f, "fasta"):
                gc_content = calculate_gc_content(str(record.seq))
                contigs[record.id] = {"length": len(record.seq), "sequence": str(record.seq), "gc_content": gc_content}
    else:
        with open(fasta_file, "r") as f:
            for record in SeqIO.parse(f, "fasta"):
                gc_content = calculate_gc_content(str(record.seq))
                contigs[record.id] = {"length": len(record.seq), "sequence": str(record.seq), "gc_content": gc_content}
    return contigs


# Function to parse the log file and extract relevant statistics
def parse_log(log_file):
    stats = {}
    with open(log_file, "r") as log:
        for line in log:
            if line.startswith("Runtime"):
                stats["run_time"] = line.split(":")[-1].strip()
            elif line.startswith("Total contigs"):
                stats["total_contigs"] = int(line.split(":")[-1].strip())
            elif line.startswith("N50"):
                stats["N50"] = int(line.split(":")[-1].strip())
            # Add more log parsing logic based on your log structure
    return stats


# Function to calculate the N50 from contig lengths
def calculate_n50(contig_lengths):
    contig_lengths.sort(reverse=True)  # Sort the contigs by length in descending order
    total_length = sum(contig_lengths)
    half_length = total_length / 2
    cumulative_length = 0

    for length in contig_lengths:
        cumulative_length += length
        if cumulative_length >= half_length:
            return length
    return 0


# Function to create the final JSON report
def create_json_report(fasta_file, log_file, output_dir):
    # Parse the files
    fasta_data = parse_fasta(fasta_file)
    log_data = parse_log(log_file)

    # Get the base file name of the FASTA file to include in the report
    fasta_file_name = os.path.basename(fasta_file)

    # Get the list of contig lengths
    contig_lengths = [fasta_data[contig_id]["length"] for contig_id in fasta_data]

    # Calculate N50
    n50 = calculate_n50(contig_lengths)

    # Combine all data into a single JSON structure
    report = {
        "file_name": fasta_file_name,  # Include the file name at the top
        "assembly_stats": {
            **log_data,
            "n50": n50,  # Add N50 to assembly stats
            "total_contigs": len(fasta_data),  # Add the total number of contigs
        },
        "contigs": [],
    }

    # Add contig information from FASTA
    for contig_id in fasta_data:
        report["contigs"].append(
            {
                "contig_id": contig_id,
                "length": fasta_data[contig_id]["length"],
                "gc_content": fasta_data[contig_id]["gc_content"],  # Include GC content
                "sequence": fasta_data[contig_id]["sequence"],
            }
        )

    # Create the output directory if it doesn't exist
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    # Write the JSON report
    json_output_path = os.path.join(output_dir, "unicycler_report.json")
    with open(json_output_path, "w") as json_file:
        json.dump(report, json_file, indent=4)
    print(f"JSON report saved at {json_output_path}")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--fasta", required=True, help="Path to the FASTA file")
    parser.add_argument("--log", required=True, help="Path to the log file")
    parser.add_argument("--output", required=True, help="Directory to save the JSON report")
    args = parser.parse_args()

    # Generate the JSON report
    create_json_report(args.fasta, args.log, args.output)


if __name__ == "__main__":
    main()
