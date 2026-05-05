#!/usr/bin/env nextflow

process SETUP_MACSYFINDER{
    publishDir path: "${params.databaseDir}", mode: 'move'
    tag "SETUP_MACSYFINDER"
    conda "${projectDir}/modules/macsyfinder/environment.yaml"

    output:
        path "macsyfinder", emit: db

    script:
    """
     msf_data install --target macsyfinder TXSScan
     msf_data install --target macsyfinder CONJScan
     msf_data install --target macsyfinder CASFinder
     echo 'Finished mamba environment setup.'
    """
}