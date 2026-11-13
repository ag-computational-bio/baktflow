#!/usr/bin/env nextflow

process SETUP_AMRFINDERPLUS {
    publishDir path: "${params.databaseDir}/versions", mode: 'move', pattern: "*.txt"
    publishDir path: "${params.databaseDir}", mode: 'move', pattern: "amrfinderplus"
    tag "SETUP_AMRFINDERPLUS"
    conda "${projectDir}/modules/amrfinderplus/environment.yaml"

    output:
        path "amrfinderplus", emit: db
        path "amrfinderplus.txt", emit: version

    script:
    """
    amrfinder_update -d amrfinderplus
    date '+%Y-%m-%d %H:%M:%S' > amrfinderplus.txt
    echo 'Finished mamba environment setup.'
    """
}