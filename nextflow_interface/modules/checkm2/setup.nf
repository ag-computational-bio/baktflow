#!/usr/bin/env nextflow

process SETUP_CHECKM2 {
    publishDir path: "${params.databaseDir}", mode: 'move'
    tag "SETUP_CHECKM2"
    conda "${projectDir}/modules/checkm2/environment.yaml"

    output:
     path "checkm2db", emit: db

    script:
    """
    checkm2 database --download --path checkm2db
    echo 'Finished mamba environment setup.'
    """
}


