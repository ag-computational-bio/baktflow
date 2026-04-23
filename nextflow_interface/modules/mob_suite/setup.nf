#!/usr/bin/env nextflow

process SETUP_MOB_SUITE {
    publishDir path: "${params.databaseDir}", mode: 'move'
    tag "SETUP_MOB_SUITE"
    conda "${projectDir}/modules/mob_suite/environment.yaml"

    output:
    path "mob_suite", emit: db

    script:
    """
    mob_init --database_directory mob_suite
    echo 'Finished mamba environment setup.'
    """
}

