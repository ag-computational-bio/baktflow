#!/usr/bin/env nextflow

process SETUP_POLYPOLISH {
    tag "SETUP_POLYPOLISH"
    conda "${projectDir}/modules/polypolish/environment.yaml"

    script:
    """
    echo 'Finished Polypolish environment setup.'
    """
}
