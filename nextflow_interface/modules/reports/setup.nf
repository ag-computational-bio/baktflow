#!/usr/bin/env nextflow

process SETUP_REPORTS {
    tag "SETUP_REPORTS"
    conda "${projectDir}/modules/reports/environment.yaml"

    script:
    """
    echo 'Finished Reports environment setup.'
    """
}
