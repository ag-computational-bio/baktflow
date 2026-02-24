#!/usr/bin/env nextflow
nextflow.enable.dsl=2

// Process to setup Fitlong
process SETUP_FILTLONG {
    tag "SETUP_FILTLONG"

    conda "${projectDir}/modules/filtlong/environment.yaml"
    if ( "${workflow.stubRun}" == "false" ) {
        cpus (params.threads >= 2 ? 2 : params.threads)
        memory {4.GB * task.attempt}
    }

    script:
    """
    echo 'Finished Filtlong environment setup.'
    """
}


    








