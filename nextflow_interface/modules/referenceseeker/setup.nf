#!/usr/bin/env nextflow

process SETUP_REFERENCESEEKER {
    publishDir path: "${params.databaseDir}", mode: 'move'
    tag "SETUP_REFERENCESEEKER"
    conda "${projectDir}/modules/referenceseeker/environment.yaml"

     output:
        path "bacteria-refseq", emit: db

    script:
    """
    wget 'https://zenodo.org/record/4415843/files/bacteria-refseq.tar.gz'
    tar -xzf bacteria-refseq.tar.gz
    echo 'Finished mamba environment setup.'
    """
}
