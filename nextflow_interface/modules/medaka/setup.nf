#!/usr/bin/env nextflow
nextflow.enable.dsl=2


params.MEDAKA_ENV_PATH = "${baseDir}/../setup/conda_envs/medaka"
params.MEDAKA_ENV_FILE = "${baseDir}/modules/medaka/environment.yaml"


// Process to setup Medaka
process SETUP_MEDAKA {
    tag "SETUP_MEDAKA"
    memory '4GB'
    cpus (params.threads >= 2 ? 2 : params.threads)

    script:
    """
    echo 'Starting Medaka environment setup...'
    echo "Conda environments path: ${params.MEDAKA_ENV_PATH}"
    mamba env create -p ${params.MEDAKA_ENV_PATH} -f ${params.MEDAKA_ENV_FILE} -v
    echo 'Finished Medaka environment setup.'
    """
}


    








