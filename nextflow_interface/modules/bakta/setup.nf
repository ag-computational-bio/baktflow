#!/usr/bin/env nextflow

process SETUP_BAKTA {
    publishDir path: "${params.databaseDir}", mode: 'move'
    tag "SETUP_BAKTA"
    conda "${projectDir}/modules/bakta/environment.yaml"

    output:
    path "bakta", emit: db

    script:
    """
    bakta_db download --type ${params.baktaDbType} --output bakta
    echo 'Finished Bakta environment setup.'
    """
}
