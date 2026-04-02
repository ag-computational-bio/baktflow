#!/usr/bin/env nextflow

process SETUP_UNICYCLER {
    tag "SETUP_UNICYCLER"
    conda "${projectDir}/modules/unicycler/environment.yaml"

    script:
    """
    echo 'Finished Unicycler environment setup.'
    """
}
