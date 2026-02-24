#!/usr/bin/env nextflow
nextflow.enable.dsl=2

process SETUP_FASTQC {
    tag "SETUP_FASTQC"

    conda "${projectDir}/modules/fastqc/environment.yaml"

    script:
    """
    echo 'Finished mamba environment setup.'
    """
}








