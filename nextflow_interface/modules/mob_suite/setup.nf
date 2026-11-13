#!/usr/bin/env nextflow

process SETUP_MOB_SUITE {
    publishDir path: "${params.databaseDir}/versions", mode: 'move', pattern: "*.txt"
    publishDir path: "${params.databaseDir}", mode: 'move', pattern:"mob_suite"
    tag "SETUP_MOB_SUITE"
    conda "${projectDir}/modules/mob_suite/environment.yaml"

    output:
    path "mob_suite", emit: db
    path "mob_suite.txt", emit: version

    script:
    """
    mob_init --database_directory mob_suite
    date '+%Y-%m-%d %H:%M:%S' > mob_suite.txt
    echo 'Finished mamba environment setup.'
    """
}

