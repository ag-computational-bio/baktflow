#!/usr/bin/env nextflow

process SETUP_RGI {
    tag "SETUP_RGI"
    conda "${projectDir}/modules/rgi/environment.yaml"

    script:
    """
    echo 'Finished mamba environment setup.'
    """
}
