#!/usr/bin/env nextflow

process SETUP_MACSYFINDER{
    
    tag "SETUP_MACSYFINDER"
    conda "${projectDir}/modules/macsyfinder/environment.yaml"


    script:
    """
     msf_data install --target ${params.modelsDir} TXSScan
     msf_data install --target ${params.modelsDir} CONJScan
     msf_data install --target ${params.modelsDir} CASFinder
     echo 'Finished mamba environment setup.'
    """
}