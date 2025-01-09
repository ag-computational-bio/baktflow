#!/usr/bin/env nextflow
nextflow.enable.dsl=2

// Define parameters with default values
params.CONDA_ENV_DIR = "$baseDir/../setup/conda_envs"
params.CONDA_ENV_PATH = "${params.CONDA_ENV_DIR}/bakta"
params.OUTPUT_DIR = "$baseDir/../output"  // Define the output directory path for Bakta results

process BAKTA_RUN {
    tag { file_map.sample_ID }

    errorStrategy 'retry'
    maxRetries 3

    input:
    tuple val(sample_ID), file(bakta_output_files), val(file_map)

    output:
    tuple val(sample_ID), file('bakta/*'), val(file_map)

    publishDir "${params.OUTPUT_DIR}/${file_map.sample_ID}/bakta", mode: 'copy'

    script:
    """
    mkdir -p bakta

    bakta run --input ${file_map.file_path} --output bakta/${file_map.sample_ID}_bakta_output \
              --config ${params.CONDA_ENV_DIR}/bakta_config.yaml

    echo "Running BAKTA on ${file_map.sample_ID}"
    """
}

















