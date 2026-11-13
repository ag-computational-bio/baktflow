#!/usr/bin/env nextflow

process SETUP_AUTOCYCLER {
    publishDir path: "${params.databaseDir}/versions", mode: 'move', pattern: "*.txt"
    publishDir path: "${params.databaseDir}", mode: 'move', pattern: "plassembler_db"
    tag "SETUP_AUTOCYCLER"
    conda "${projectDir}/modules/autocycler/environment.yaml"

    output:
    path "plassembler_db", emit: db
    path "plassembler.txt", emit: version

    script:
    """
    plassembler download -d plassembler_db
    date '+%Y-%m-%d %H:%M:%S' > plassembler.txt
    echo 'Finished Autocycler environment setup.'
    """
}
