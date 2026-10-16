#!/usr/bin/env nextflow

process SETUP_CONTIGMAPPING {
    tag "SETUP_CONTIGMAPPING"
    conda "${projectDir}/modules/contigmapping/environment.yaml"

    script:
    """
    echo 'Finished environment setup.'
    """
}
