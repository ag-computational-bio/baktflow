#!/usr/bin/env nextflow

process SETUP_BAKTA {
    publishDir path: "${params.databaseDir}/versions", mode: 'move', pattern: "*.txt"
    publishDir path: "${params.databaseDir}", mode: 'move', pattern: "bakta"
    tag "SETUP_BAKTA"
    conda "${projectDir}/modules/bakta/environment.yaml"

    output:
    path "bakta", emit: db
    path "bakta.txt", emit: version

    script:
    """
    bakta_db download --type ${params.baktaDbType} --output bakta
    date '+%Y-%m-%d %H:%M:%S' > bakta.txt
    echo 'Finished Bakta environment setup.'
    """
}
