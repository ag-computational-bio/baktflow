#!/usr/bin/env nextflow

process SETUP_MEDAKA {
    tag "SETUP_MEDAKA"
    conda "${projectDir}/modules/medaka/environment.yaml"

    script:
    """
    echo 'Finished Medaka environment setup.'
    """
}
