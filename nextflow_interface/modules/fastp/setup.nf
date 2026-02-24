#!/usr/bin/env nextflow
nextflow.enable.dsl=2

params.FASTP_ENV_FILE = "${projectDir}/modules/fastp/environment.yaml"
params.FASTP_ENV_PATH = "${projectDir}/../setup/conda_envs/fastp"

process SETUP_FASTP {
    tag "SETUP_FASTP"

    conda "${projectDir}/modules/fastp/environment.yaml"
    if ( "${workflow.stubRun}" == "false" ) {
        cpus (params.threads >= 2 ? 2 : params.threads)
        memory {4.GB * task.attempt}
    }

    script:
    """
    echo 'Finished mamba environment setup.'
    """
}








