#!/usr/bin/env nextflow

process SETUP_FASTPLONG {
    tag "SETUP_FASTPLONG"
    conda "${projectDir}/modules/fastplong/environment.yaml"

    script:
    """
    echo 'Finished Fastplong environment setup.'
    """
}
