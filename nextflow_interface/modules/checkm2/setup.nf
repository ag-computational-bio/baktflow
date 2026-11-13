#!/usr/bin/env nextflow

process SETUP_CHECKM2 {
    publishDir path: "${params.databaseDir}/versions", mode: 'move', pattern: "*.txt"
    publishDir path: "${params.databaseDir}", mode: 'move', pattern: "checkm2db"
    tag "SETUP_CHECKM2"
    conda "${projectDir}/modules/checkm2/environment.yaml"
    errorStrategy { (task.attempt <= 3) ? 'retry' : 'ignore' }

    output:
     path "checkm2db", emit: db
     path "checkm2", emit: version

    script:
    """
    checkm2 database --download --path checkm2db
    date '+%Y-%m-%d %H:%M:%S' > checkm2.txt
    echo 'Finished mamba environment setup.'
    """
}


