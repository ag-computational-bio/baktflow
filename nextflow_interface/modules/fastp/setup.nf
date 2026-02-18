#!/usr/bin/env nextflow
nextflow.enable.dsl=2

params.FASTP_ENV_FILE = "${baseDir}/modules/fastp/environment.yaml"
params.FASTP_ENV_PATH = "${baseDir}/../setup/conda_envs/fastp"

process SETUP_FASTP {
    tag "SETUP_FASTP"
    if ( "${workflow.stubRun}" == "false" ) {
        memory {4.GB * task.attempt}
    }
    cpus (params.threads >= 2 ? 2 : params.threads)

    script:
    """
    echo 'Starting mamba environment setup...'
    echo "Conda environments path: ${params.FASTP_ENV_PATH}"
    mamba env create -p ${params.FASTP_ENV_PATH} -f ${params.FASTP_ENV_FILE} -v
    echo 'Finished mamba environment setup.'

    """
}








