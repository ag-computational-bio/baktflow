#!/usr/bin/env nextflow

process SETUP_ANTISMASH {
    publishDir path: "${params.databaseDir}", mode: 'move'
    tag "SETUP_ANTISMASH"
    conda "${projectDir}/modules/antismash/environment.yaml"

    output:
        path "antismash", emit: db

    script:
    """
    mkdir antismash
    download-antismash-databases --database-dir antismash
    echo 'Finished Gecco environment setup.'
    """
}
