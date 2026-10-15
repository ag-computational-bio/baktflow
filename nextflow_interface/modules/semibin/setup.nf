#!/usr/bin/env nextflow

process SETUP_SEMIBIN {
    tag "SETUP_SEMIBIN"
    conda "${projectDir}/modules/semibin/environment.yaml"

    script:
    """
    echo 'Finished environment setup.'
    """
}
