#!/usr/bin/env nextflow

process SETUP_BLAST {
    publishDir path: "${params.databaseDir}", mode: 'move'
    tag "SETUP_BLAST"
    conda "${projectDir}/modules/blast/environment.yaml"

    output:
        path "silva_db", emit: db

    script:
    """
    wget -O silva.fasta.gz 'https://www.arb-silva.de/fileadmin/silva_databases/current/Exports/SILVA_138.2_SSURef_NR99_tax_silva.fasta.gz'
    gunzip silva.fasta.gz
    mkdir silva_db
    makeblastdb -in silva.fasta -dbtype nucl -out silva_db/silva_db
    echo 'Finished mamba environment setup.'
    """
}