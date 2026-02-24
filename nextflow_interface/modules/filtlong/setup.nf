#!/usr/bin/env nextflow
nextflow.enable.dsl=2

// Define parameters for tools
params.FILTLONG_ENV_FILE = "${baseDir}/modules/filtlong/environment.yaml"
params.FILTLONG_ENV_PATH = "${baseDir}/../setup/conda_envs/filtlong"


// Process to setup Fitlong
process SETUP_FILTLONG {
    tag "SETUP_FILTLONG"
    if ( "${workflow.stubRun}" == "false" ) {
        cpus (params.threads >= 2 ? 2 : params.threads)
        memory {4.GB * task.attempt}
    }

    script:
    """
    echo 'Starting Filtlong environment setup...'
    echo "Conda environments path: ${params.FILTLONG_ENV_PATH}"
    mamba env create -p ${params.FILTLONG_ENV_PATH} -f ${params.FILTLONG_ENV_FILE} -v
    echo 'Finished Filtlong environment setup.'
    """
}


    








