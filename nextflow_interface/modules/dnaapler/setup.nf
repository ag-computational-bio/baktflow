#!/usr/bin/env nextflow
nextflow.enable.dsl=2

// Process to setup DNAapler
process SETUP_DNAAPLER {
    tag "SETUP_DNAAPLER"

    conda "${projectDir}/modules/dnaapler/environment.yaml"

    script:
    """
    echo 'Finished DNAapler environment setup.'
    """
}


    








