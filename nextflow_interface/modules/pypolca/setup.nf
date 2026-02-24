#!/usr/bin/env nextflow
nextflow.enable.dsl=2

// Define parameters for  Pypolca
params.PYPOLCA_ENV_FILE = "${baseDir}/modules/pypolca/environment.yaml"
params.PYPOLCA_ENV_PATH = "${baseDir}/../setup/conda_envs/pypolca"
// Process to setup Pypolca
process SETUP_PYPOLCA {
    tag "SETUP_PYPOLCA"
    if ( "${workflow.stubRun}" == "false" ) {
        cpus (params.threads >= 2 ? 2 : params.threads)
        memory {4.GB * task.attempt}
    }

    script:
    """
    echo 'Starting Pypolca environment setup...'
    echo "Conda environments path: ${params.PYPOLCA_ENV_PATH}"
    mamba env create -p ${params.PYPOLCA_ENV_PATH} -f ${params.PYPOLCA_ENV_FILE} -v
    echo 'Finished Pypolca environment setup.'
    """
}

    








