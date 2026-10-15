#!/usr/bin/env nextflow

process SETUP_SYLPH {
    tag "SETUP_SYLPH"
    publishDir path: "${params.databaseDir}/sylph", mode: 'move'
    conda "${projectDir}/modules/sylph/environment.yaml"

    output:
        path "https://faust.compbio.cs.cmu.edu/sylph-stuff/globdb_r232_sylph_v2_c200.syl2db", emit: db

    script:
    """
    wget https://faust.compbio.cs.cmu.edu/sylph-stuff/globdb_r232_sylph_v2_c200.syl2db
    """
}
