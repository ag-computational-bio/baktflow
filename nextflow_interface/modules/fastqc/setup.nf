#!/usr/bin/env nextflow
nextflow.enable.dsl=2

params.FASTQC_ENV_FILE = "${baseDir}/modules/fastqc/environment.yaml"
params.FASTQC_ENV_PATH = "${baseDir}/../setup/conda_envs/fastqc"

process SETUP_FASTQC {
    tag "SETUP_FASTQC"
    memory '4GB'
    cpus (params.threads >= 2 ? 2 : params.threads)

    script:
    """
    echo 'Starting Fastqc environment setup...'
    echo "Conda environments path: ${params.FASTQC_ENV_PATH}"
    mamba env create -p ${params.FASTQC_ENV_PATH} -f ${params.FASTQC_ENV_FILE}
    """
}








