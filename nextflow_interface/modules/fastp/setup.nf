#!/usr/bin/env nextflow
nextflow.enable.dsl=2

params.FASTP_ENV_FILE = "${projectDir}/modules/fastp/environment.yaml"
params.FASTP_ENV_PATH = "${projectDir}/../setup/conda_envs/fastp"

process SETUP_FASTP {
    tag "SETUP_FASTP"

    conda "${projectDir}/modules/fastp/environment.yaml"

    script:
    """
    echo 'Finished mamba environment setup.'
    """
}








