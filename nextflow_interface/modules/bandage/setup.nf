#!/usr/bin/env nextflow

process SETUP_B {
    tag "SETUP_BANDAGE"
    conda "${projectDir}/modules/bandage/environment.yaml"

    script:
    """
    echo 'Finished mamba environment setup.'
    """
}
