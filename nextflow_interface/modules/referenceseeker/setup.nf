#!/usr/bin/env nextflow

process SETUP_REFERENCESEEKER {
    publishDir path: "${params.databaseDir}/versions", mode: 'move', pattern: "*.txt"
    publishDir path: "${params.databaseDir}", mode: 'move', pattern: "bacteria-refseq"
    tag "SETUP_REFERENCESEEKER"
    conda "${projectDir}/modules/referenceseeker/environment.yaml"

     output:
        path "bacteria-refseq", emit: db
        path "referenceseeker.txt", emit: version

    script:
    """
    wget 'https://zenodo.org/record/4415843/files/bacteria-refseq.tar.gz'
    tar -xzf bacteria-refseq.tar.gz
    rm bacteria-refseq.tar.gz
    date '+%Y-%m-%d %H:%M:%S' > referenceseeker.txt
    echo 'Finished mamba environment setup.'
    """
}
