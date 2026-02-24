#!/usr/bin/env nextflow
nextflow.enable.dsl=2

// Process to setup Unicycler
process SETUP_UNICYCLER {
    tag "SETUP_UNICYCLER"

    conda "${projectDir}/modules/unicycler/environment.yaml"
    if ( "${workflow.stubRun}" == "false" ) {
        cpus (params.threads >= 2 ? 2 : params.threads)
        memory {4.GB * task.attempt}
    }

    script:
    """
    echo 'Finished Unicycler environment setup.'
    """
}



    








