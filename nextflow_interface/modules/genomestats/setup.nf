#!/usr/bin/env nextflow

process SETUP_GENOMESTATS {
    tag "SETUP_GENOMESTATS"
    conda "${projectDir}/modules/genomestats/environment.yaml"

    script:
    """
    echo 'Finished genomestats environment setup.'
    """
}
