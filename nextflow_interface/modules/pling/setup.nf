#!/usr/bin/env nextflow

process SETUP_PLING {
    tag "SETUP_PLING"
    conda "${projectDir}/modules/pling/environment.yaml"

    script:
    """
    echo 'Finished mamba environment setup.'
    """
}