#!/usr/bin/env nextflow

process SETUP_AMRFINDERPLUS {
    publishDir path: "${params.databaseDir}", mode: 'move'
    tag "SETUP_AMRFINDERPLUS"
    conda "${projectDir}/modules/amrfinderplus/environment.yaml"

    output:
        path "amrfinderplus", emit: db

    script:
    """
    amrfinder_update -d amrfinderplus
    echo 'Finished mamba environment setup.'
    """
}