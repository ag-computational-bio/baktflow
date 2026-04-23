#!/usr/bin/env nextflow

process SETUP_SKA {
    tag "SETUP_SKA"
    conda "${projectDir}/modules/ska/environment.yaml"

    script:
    """
    echo 'Finished mamba environment setup.'
    """
}
