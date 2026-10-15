#!/usr/bin/env nextflow

process SETUP_NANOPLOT {
    tag "SETUP_NANOPLOT"
    conda "${projectDir}/modules/nanoplot/environment.yaml"

    script:
    """
    echo 'Finished mamba environment setup.'
    """
}
