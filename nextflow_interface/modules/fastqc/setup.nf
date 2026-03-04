#!/usr/bin/env nextflow

process SETUP_FASTQC {
    tag "SETUP_FASTQC"
    conda "${projectDir}/modules/fastqc/environment.yaml"

    script:
    """
    echo 'Finished mamba environment setup.'
    """
}
