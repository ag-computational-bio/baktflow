#!/usr/bin/env nextflow
nextflow.enable.dsl=2

// Process to setup Medaka
process SETUP_MEDAKA {
    tag "SETUP_MEDAKA"

    conda "${projectDir}/modules/medaka"

    script:
    """
    echo 'Finished Medaka environment setup.'
    """
}


    








