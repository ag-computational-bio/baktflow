#!/usr/bin/env nextflow

process SETUP_MACSYFINDER{
    publishDir path: "${params.databaseDir}/versions", mode: 'move', pattern: ".*txt"
    publishDir path: "${params.databaseDir}", mode: 'move', pattern: "macsyfinder"
    tag "SETUP_MACSYFINDER"
    conda "${projectDir}/modules/macsyfinder/environment.yaml"

    output:
        path "macsyfinder", emit: db
        path "macsyfinder.txt", emit: version

    script:
    """
     msf_data install --target macsyfinder TXSScan
     msf_data install --target macsyfinder CONJScan
     msf_data install --target macsyfinder CASFinder
     date '+%Y-%m-%d %H:%M:%S' > macsyfinder.txt
     echo 'Finished mamba environment setup.'
    """
}