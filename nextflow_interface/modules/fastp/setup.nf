#!/usr/bin/env nextflow
nextflow.enable.dsl=2

params.FASTP_ENV_FILE = "${baseDir}/modules/fastp/environment.yaml"
params.FASTP_ENV_PATH = "${baseDir}/../setup/conda_envs/fastp"

process SETUP_FASTP {
    tag "SETUP_FASTP"
    memory '4GB'
    cpus 2
    script:
    """
    echo 'Starting mamba environment setup...'
     echo "Conda environments path: ${params.FASTP_ENV_PATH}"
    mamba env create -p ${params.FASTP_ENV_PATH} -f ${params.FASTP_ENV_FILE} -v
    echo 'Finished mamba environment setup.'
    """
}








