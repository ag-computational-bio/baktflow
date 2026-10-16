#!/usr/bin/env nextflow

process SETUP_NANOLYSE {
    tag "SETUP_NANOLYSE"
    conda "${projectDir}/modules/nanolyse/environment.yaml"

    script:
    """
    echo 'Finished environment setup.'
    """
}
