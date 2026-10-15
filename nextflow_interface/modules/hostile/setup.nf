#!/usr/bin/env nextflow

process SETUP_HOSTILE {
    publishDir path: "${params.databaseDir}", mode: 'move'
    tag "SETUP_HOSTILE"
    conda "${projectDir}/modules/hostile/environment.yaml"

    output:
        path "hostile", emit: db

    script:
    """
    mkdir hostile
    export HOSTILE_CACHE_DIR="./hostile"
    hostile index fetch --minimap2 --name human-t2t-hla-argos985-mycob140
    """
}
