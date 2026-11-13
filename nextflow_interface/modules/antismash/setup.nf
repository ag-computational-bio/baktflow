#!/usr/bin/env nextflow

process SETUP_ANTISMASH {
    publishDir path: "${params.databaseDir}/versions", mode: 'move', pattern: "*.txt"
    publishDir path: "${params.databaseDir}", mode: 'move', pattern: "antismash"
    tag "SETUP_ANTISMASH"
    conda "${projectDir}/modules/antismash/environment.yaml"

    output:
        path "antismash", emit: db
        path "antismash.txt", emit: version

    script:
    """
    date '+%Y-%m-%d %H:%M:%S' > antismash.txt
    mkdir antismash
    download-antismash-databases --database-dir antismash
    echo 'Finished Gecco environment setup.'
    """
}
