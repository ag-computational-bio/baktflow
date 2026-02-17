#!/usr/bin/env nextflow
nextflow.enable.dsl=2

// Define parameters with default values
params.CONDA_ENV_DIR = "$baseDir/../setup/conda_envs"
params.CONDA_ENV_PATH = "${params.CONDA_ENV_DIR}/dnaapler"
params.OUTPUT_DIR = "$baseDir/../output"

process DNAAPLER {
    input:
    tuple val(meta), path(input_fasta)

    output:
    tuple val(meta), path("${meta.sample_id}_reoriented.fasta"), emit: assembly

    publishDir "${params.OUTPUT_DIR}/${meta.sample_id}/dnaapler", mode: 'copy'
    conda "${params.CONDA_ENV_PATH}"
    cpus (params.threads >= 8 ? 8 : params.threads)
    memory {1.GB * task.attempt}

    script:
    def prefix = meta.sample_id
    def output_fasta = "${prefix}_reoriented.fasta"
    def temp_fasta = "${prefix}.fasta"  // Temporary file for decompressed input

    """
    # If input file is gzipped, decompress it first
    if [[ "${input_fasta}" == *.gz ]]; then
        gunzip -c "${input_fasta}" > "${temp_fasta}"
        input_fasta="${temp_fasta}"  # Update input_fasta to the decompressed file
    else
        # If it's not gzipped, just assign temp_fasta as input_fasta
        cp "${input_fasta}" "${temp_fasta}"  # Or simply assign the file if needed
    fi

    # Check if the input file is a valid FASTA format
    if ! grep -q "^>" "${input_fasta}"; then
        echo "Error: Input file ${input_fasta} is not in FASTA format!" >&2
        exit 1
    fi

    # Run dnaapler with the force flag to overwrite existing output
    dnaapler all \\
        -i "${temp_fasta}" \\
        -o "${prefix}_dnaapler_output" \\
        -t $task.cpus \\
        -p "${prefix}" \\
        --force

    # Check if the reoriented file exists and move it to the output location
    if [[ -f "${prefix}_dnaapler_output/${prefix}_reoriented.fasta" ]]; then
        mv "${prefix}_dnaapler_output/${prefix}_reoriented.fasta" "${output_fasta}"
    else
        echo "Error: Expected output file not found!" >&2
        exit 1
    fi
    """
}























