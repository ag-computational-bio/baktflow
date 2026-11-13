#!/usr/bin/env nextflow

process SETUP_PLASMIDFINDER {
    publishDir path: "${params.databaseDir}/versions", mode: 'move', pattern: "*.txt"
    tag "SETUP_PLASMIDFINDER"
    conda "${projectDir}/modules/plasmidfinder/environment.yaml"

    output:
    path "plasmidfinder.txt", emit: version

    script:
    """
    download-db.sh
    date '+%Y-%m-%d %H:%M:%S' > plasmidfinder.txt
    echo 'Finished mamba environment setup.'
    """
}
