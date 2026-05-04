#!/usr/bin/env nextflow

process SETUP_MACSYFINDER{
    
    tag "SETUP_MACSYFINDER"
    conda "${projectDir}/modules/macsyfinder/environment.yaml"


    script:
    """
     msf_data install --target ${params.databaseDir}/macsyfinder TXSScan
     msf_data install --target ${params.databaseDir}/macsyfinder CONJScan
     msf_data install --target ${params.databaseDir}/macsyfinder CASFinder
     echo 'Finished mamba environment setup.'
    """
}