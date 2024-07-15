#!/usr/bin/env nextflow
nextflow.enable.dsl=2

params.FASTP_ENV_FILE = "${baseDir}/modules/fastp/environment.yaml"

process SETUP_FASTP {
    tag "SETUP_FASTPC"



    conda "${params.FASTP_ENV_FILE}"

   

    script:
    """
    echo "Installing fastp using Mamba..."
    echo "fastp installation completed."
    """
}









