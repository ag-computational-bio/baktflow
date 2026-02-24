#!/usr/bin/env nextflow
nextflow.enable.dsl=2

// Process to setup DNAapler
process SETUP_DNAAPLER {
    tag "SETUP_DNAAPLER"

    conda "${projectDir}/modules/dnaapler/environment.yaml"
    if ( "${workflow.stubRun}" == "false" ) {
        cpus (params.threads >= 2 ? 2 : params.threads)
        memory {4.GB * task.attempt}
    }

    script:
    """
    echo 'Finished DNAapler environment setup.'
    """
}


    








