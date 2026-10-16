#!/usr/bin/env nextflow

process SETUP_MYLOASM {
    tag "SETUP_MYLOASM"
    conda "${projectDir}/modules/myloasm/environment.yaml"

    script:
    """
    echo 'Finished environment setup.'
    """
}
