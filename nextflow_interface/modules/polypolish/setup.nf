#!/usr/bin/env nextflow
nextflow.enable.dsl=2

// Define parameters for Polypolish 
params.POLYPOLISH_ENV_FILE = "${baseDir}/modules/polypolish/environment.yaml"
params.POLYPOLISH_ENV_PATH = "${baseDir}/../setup/conda_envs/polypolish"


// Process to setup Polypolish
process SETUP_POLYPOLISH {
    tag "SETUP_POLYPOLISH"
    memory {4.GB * task.attempt}
    cpus (params.threads >= 2 ? 2 : params.threads)

    script:
    """
    echo 'Starting Polypolish environment setup...'
    echo "Conda environments path: ${params.POLYPOLISH_ENV_PATH}"
    mamba env create -p ${params.POLYPOLISH_ENV_PATH} -f ${params.POLYPOLISH_ENV_FILE} -v
    echo 'Finished Polypolish environment setup.'
    """
}

    








