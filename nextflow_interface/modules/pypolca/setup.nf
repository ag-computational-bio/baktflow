#!/usr/bin/env nextflow

process SETUP_PYPOLCA {
    tag "SETUP_PYPOLCA"
    conda "${projectDir}/modules/pypolca/environment.yaml"

    script:
    """
    echo 'Finished Pypolca environment setup.'
    """
}
