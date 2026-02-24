#!/usr/bin/env nextflow
nextflow.enable.dsl=2

// Process to setup Flye
process SETUP_FLYE {
    tag "SETUP_FLYE"

    conda "${projectDir}/modules/flye/environment.yaml"

    script:
    """
    echo 'Finished Flye environment setup.'
    """
}


    








