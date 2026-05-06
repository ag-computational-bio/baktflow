#!/usr/bin/env nextflow

process SETUP_KLEBORATE {
    tag "SETUP_KLEBORATE"
    conda "${projectDir}/modules/kleborate/environment.yaml"

    script:
    """
    echo 'Finished mamba environment setup.'
    """
}
