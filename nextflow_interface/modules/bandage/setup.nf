#!/usr/bin/env nextflow

process SETUP_BANDAGE {
    tag "SETUP_BANDAGE"
    conda "${projectDir}/modules/bandage/environment.yaml"

    script:
    """
    echo 'Finished mamba environment setup.'
    """
}
