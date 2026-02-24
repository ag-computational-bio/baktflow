#!/usr/bin/env nextflow

params.BAKTA_DB_TYPE = "light"  // Valid options: light, full

process SETUP_BAKTA {
    publishDir path: "${params.databaseDir}", mode: 'copy'
    tag "SETUP_BAKTA"
    conda "${projectDir}/modules/bakta/environment.yaml"

    output:
    path "bakta", emit: db

    script:
    """
    bakta_db download --type ${params.BAKTA_DB_TYPE} --output bakta
    echo 'Finished Bakta environment setup.'
    """
}
