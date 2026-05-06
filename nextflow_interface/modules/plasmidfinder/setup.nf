#!/usr/bin/env nextflow

process SETUP_PLASMIDFINDER {
    tag "SETUP_PLASMIDFINDER"
    conda "${projectDir}/modules/plasmidfinder/environment.yaml"

    script:
    """
    download-db.sh
    echo 'Finished mamba environment setup.'
    """
}
