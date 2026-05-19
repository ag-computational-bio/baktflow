#!/usr/bin/env nextflow

process SETUP_ECTYPER {
    tag "SETUP_ECTYPER"
    conda "${projectDir}/modules/ectyper/environment.yaml"

    script:
    """
    ectyper_init
    echo 'Finished mamba environment setup.'
    """
}