#!/usr/bin/env nextflow
nextflow.enable.dsl=2

// Process to setup Polypolish
process SETUP_POLYPOLISH {
    tag "SETUP_POLYPOLISH"

    conda "${projectDir}/modules/polypolish/environment.yaml"
    if ( "${workflow.stubRun}" == "false" ) {
        cpus (params.threads >= 2 ? 2 : params.threads)
        memory {4.GB * task.attempt}
    }

    script:
    """
    echo 'Finished Polypolish environment setup.'
    """
}

    








