#!/usr/bin/env nextflow

process SETUP_MLST {
    tag "SETUP_MLST"
    conda "${projectDir}/modules/mlst/environment.yaml"

    script:
    """
    echo 'Finished mamba environment setup.'
    """
}
