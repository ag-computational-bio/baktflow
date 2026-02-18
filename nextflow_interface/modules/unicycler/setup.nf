#!/usr/bin/env nextflow
nextflow.enable.dsl=2

// Define parameters for FastQC
params.UNICYCLER_ENV_FILE = "${baseDir}/modules/unicycler/environment.yaml"
params.UNICYCLER_ENV_PATH = "${baseDir}/../setup/conda_envs/unicycler"

// Process to setup Unicycler
process SETUP_UNICYCLER {
    tag "SETUP_UNICYCLER"
    if ( "${workflow.stubRun}" == "false" ) {
        memory {4.GB * task.attempt}
    }
    cpus (params.threads >= 2 ? 2 : params.threads)

    script:
    """
    echo 'Starting Unicycler environment setup...'
    echo "Conda environments path: ${params.UNICYCLER_ENV_PATH}"
    mamba env create -p ${params.UNICYCLER_ENV_PATH} -f ${params.UNICYCLER_ENV_FILE} -v 
    """
}



    








