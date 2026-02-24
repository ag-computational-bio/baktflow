#!/usr/bin/env nextflow
nextflow.enable.dsl=2

// Process to setup Fitlong
process SETUP_FILTLONG {
    tag "SETUP_FILTLONG"

    conda "${projectDir}/modules/filtlong/environment.yaml"

    script:
    """
    echo 'Finished Filtlong environment setup.'
    """
}


    








