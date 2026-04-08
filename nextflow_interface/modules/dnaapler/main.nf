#!/usr/bin/env nextflow

process DNAAPLER {
    publishDir "${params.output}/${meta.sample_id}/dnaapler", mode: 'copy'
    conda "${projectDir}/modules/dnaapler/environment.yaml"
    memory { workflow.stubRun ? 64.MB : 1.GB * task.attempt }
    cpus { workflow.stubRun ? 1 : (params.threads >= 8 ? 8 : params.threads) }

    input:
        tuple val(meta), path(input_fasta)

    output:
        tuple val(meta), path("${meta.sample_id}_reoriented.fasta"), emit: assembly

    script:
    """
    # If input file is gzipped, decompress it first
    if [[ "${input_fasta}" == *.gz ]]; then
        gunzip -c "${input_fasta}" > "${meta.sample_id}.fasta"
        input_fasta="${meta.sample_id}.fasta"  # Update input_fasta to the decompressed file
    else
        # If it's not gzipped, just assign temp_fasta as input_fasta
        cp "${input_fasta}" "${meta.sample_id}.fasta"  # Or simply assign the file if needed
    fi

    # Check if the input file is a valid FASTA format
    if ! grep -q "^>" "${input_fasta}"; then
        echo "Error: Input file ${input_fasta} is not in FASTA format!" >&2
        exit 1
    fi

    # Run dnaapler with the force flag to overwrite existing output
    dnaapler all \\
        --input "${meta.sample_id}.fasta" \\
        --output "${meta.sample_id}_dnaapler_output" \\
        --threads $task.cpus \\
        --prefix "${meta.sample_id}"

    # Check if the reoriented file exists and move it to the output location
    if [[ -f "${meta.sample_id}_dnaapler_output/${meta.sample_id}_reoriented.fasta" ]]; then
        mv "${meta.sample_id}_dnaapler_output/${meta.sample_id}_reoriented.fasta" "${meta.sample_id}_reoriented.fasta"
    else
        echo "Error: Expected output file not found!" >&2
        exit 1
    fi
    """

    stub:
    """
    touch ${meta.sample_id}_reoriented.fasta
    """
}
