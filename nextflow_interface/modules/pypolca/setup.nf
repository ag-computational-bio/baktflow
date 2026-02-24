#!/usr/bin/env nextflow
nextflow.enable.dsl=2

// Process to setup Pypolca
process SETUP_PYPOLCA {
    tag "SETUP_PYPOLCA"

    conda "${projectDir}/modules/pypolca/environment.yaml"

    script:
    """
    echo 'Finished Pypolca environment setup.'
    """
}
