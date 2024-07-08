#!/usr/bin/env nextflow
nextflow.enable.dsl=2

params.FASTQC_ENV_FILE = "${baseDir}/modules/fastqc/environment.yaml"

process SETUP_FASTQC {
    tag "SETUP_FASTQC"



    conda "${params.FASTQC_ENV_FILE}"

    publishDir "${params.CONDA_DIR}", mode: 'copy'

    script:
    """
    echo "Installing FastQC using Mamba..."
    echo "FastQC installation completed."
    """
}








