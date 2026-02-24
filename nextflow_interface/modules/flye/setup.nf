#!/usr/bin/env nextflow
nextflow.enable.dsl=2

// Define parameters for tools

params.FLYE_ENV_FILE = "${projectDir}/modules/flye/environment.yaml"
params.FLYE_ENV_PATH = "${projectDir}/../setup/conda_envs/flye"

// Process to setup Flye
process SETUP_FLYE {
    tag "SETUP_FLYE"
    if ( "${workflow.stubRun}" == "false" ) {
        cpus (params.threads >= 2 ? 2 : params.threads)
        memory {4.GB * task.attempt}
    }

    script:
    """
    echo 'Starting Flye environment setup...'
    echo "Conda environments path: ${params.FLYE_ENV_PATH}"
    mamba env create -p ${params.FLYE_ENV_PATH} -f ${params.FLYE_ENV_FILE} -v
    echo 'Finished Flye environment setup.'
    """
}


    








