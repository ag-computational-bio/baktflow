#!/usr/bin/env nextflow

process SETUP_AUTOCYCLER {
    publishDir path: "${params.databaseDir}", mode: 'move'
    tag "SETUP_AUTOCYCLER"
    conda "${projectDir}/modules/autocycler/environment.yaml"

    output:
    path "plassembler_db", emit: db

    script:
    """
    plassembler download -d plassembler_db
    echo 'Finished Autocycler environment setup.'
    """
}
