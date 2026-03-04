#!/usr/bin/env nextflow

process SETUP_FILTLONG {
    tag "SETUP_FILTLONG"
    conda "${projectDir}/modules/filtlong/environment.yaml"

    script:
    """
    echo 'Finished Filtlong environment setup.'
    """
}
