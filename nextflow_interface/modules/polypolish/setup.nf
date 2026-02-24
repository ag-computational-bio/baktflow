#!/usr/bin/env nextflow
nextflow.enable.dsl=2

// Process to setup Polypolish
process SETUP_POLYPOLISH {
    tag "SETUP_POLYPOLISH"

    conda "${projectDir}/modules/polypolish/environment.yaml"

    script:
    """
    echo 'Finished Polypolish environment setup.'
    """
}

    








