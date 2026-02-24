#!/usr/bin/env nextflow

process SETUP_FLYE {
    tag "SETUP_FLYE"
    conda "${projectDir}/modules/flye/environment.yaml"

    script:
    """
    echo 'Finished Flye environment setup.'
    """
}
