#!/usr/bin/env nextflow

process SETUP_PLATON {
    publishDir path: "${params.databaseDir}/versions", mode: 'move', pattern: "*.txt"
    publishDir path: "${params.databaseDir}", mode: 'move', pattern: "platon_db"
    tag "SETUP_PLATON"
    conda "${projectDir}/modules/platon/environment.yaml"

    output:
    path "platon_db", emit: db
    path "platon_db.txt", emit: version

    script:
    """
    wget -O platon_db.tar.gz 'https://zenodo.org/records/4066768/files/db.tar.gz?download=1'
    tar -xzf platon_db.tar.gz
    rm platon_db.tar.gz
    mv db platon_db
    date '+%Y-%m-%d %H:%M:%S' > platon_db.txt
    echo 'Finished mamba environment setup.'
    """
}
