#!/usr/bin/env nextflow

process SETUP_METACAT {
    tag "SETUP_METACAT"
    conda "${projectDir}/modules/metacat/environment.yaml"

    script:
    """
    echo 'Finished environment setup.'
    """
}
