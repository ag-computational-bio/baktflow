#!/usr/bin/env nextflow

process SETUP_FASTP {
    tag "SETUP_FASTP"
    conda "${projectDir}/modules/fastp/environment.yaml"

    script:
    """
    echo 'Finished mamba environment setup.'
    """
}
