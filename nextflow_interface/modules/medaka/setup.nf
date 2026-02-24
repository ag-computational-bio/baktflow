#!/usr/bin/env nextflow
nextflow.enable.dsl=2

// Process to setup Medaka
process SETUP_MEDAKA {
    tag "SETUP_MEDAKA"

    conda "${projectDir}/../setup/conda_envs/medaka"
    if ( "${workflow.stubRun}" == "false" ) {
        cpus (params.threads >= 2 ? 2 : params.threads)
        memory {4.GB * task.attempt}
    }

    script:
    """
    echo 'Finished Medaka environment setup.'
    """
}


    








