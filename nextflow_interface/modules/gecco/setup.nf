#!/usr/bin/env nextflow

process SETUP_GECCO {
    tag "SETUP_GECCO"
    conda "${projectDir}/modules/gecco/environment.yaml"

    script:
    """
    echo 'Finished Gecco environment setup.'
    """
}
