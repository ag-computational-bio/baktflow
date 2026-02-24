#!/usr/bin/env nextflow
nextflow.enable.dsl=2

// Process to setup Flye
process SETUP_FLYE {
    tag "SETUP_FLYE"

    conda "${projectDir}/modules/flye/environment.yaml"
    if ( "${workflow.stubRun}" == "false" ) {
        cpus (params.threads >= 2 ? 2 : params.threads)
        memory {4.GB * task.attempt}
    }

    script:
    """
    echo 'Finished Flye environment setup.'
    """
}


    








