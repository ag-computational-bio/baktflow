#!/usr/bin/env nextflow
nextflow.enable.dsl=2
// Define parameters with default values
params.CONDA_ENV_DIR = params.CONDA_ENV_DIR ?: "/Users/naouel/Downloads/baktflow/setup/conda_envs"


// Process to run FastP analysis
process FASTP_ANALYSIS {
    tag { file_map.sample_ID }

// Set the retry strategy to handle transient errors
    errorStrategy 'retry'
    maxRetries 3

    input:
    val(file_map)  // Input hashmap with sample information

    output:
    tuple val(file_map.sample_ID), file('fastp/*'), val(file_map)

    publishDir "${params.OUTPUT_DIR}/${file_map.sample_ID}/${file_map.file_type}", mode: 'copy'

    script:
    """
    # Print the contents of the conda environment directory for debugging
    echo "Listing contents of Conda environment directory at ${params.CONDA_ENV_DIR}"
    ls -l ${params.CONDA_ENV_DIR}  # List all directories in conda_envs

    # Dynamically find the fastp environment path
    fastp_env_path=\$(find ${params.CONDA_ENV_DIR} -type d -name "fastp-*")
    echo "Located fastp environment path: \$fastp_env_path"

    if [[ -z "\$fastp_env_path" ]]; then
        echo "Error: fastp Conda environment not found in ${params.CONDA_ENV_DIR}" >&2
        exit 1
    fi

    # Activate the environment
    source activate "\$fastp_env_path"  # Activate the environment
    echo "Using FastP Conda environment: \$fastp_env_path"  # Log the active path

    # Ensure the output directory exists
    mkdir -p fastp

    # Run FastP
    fastp --in1 ${file_map.file_path} --out1 fastp/${file_map.sample_ID}_${file_map.file_type}.fastq.gz \
          --detect_adapter_for_pe --trim_poly_g --cut_front --cut_tail --length_required 21 \
          --low_complexity_filter --correction \
          -h fastp/${file_map.sample_ID}_${file_map.file_type}_report.html \
          -j fastp/${file_map.sample_ID}_${file_map.file_type}_report.json

    # Log the process for debugging
    echo "Running FastP on ${file_map.file_type} for sample: ${file_map.sample_ID}"
    """
}

















