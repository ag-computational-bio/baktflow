#!/usr/bin/env nextflow

process SETUP_METABINNER {
    tag "SETUP_METABINNER"
    conda "${projectDir}/modules/metabinner/environment.yaml"

    script:
    """
    echo 'Finished environment setup.'
    """
}
