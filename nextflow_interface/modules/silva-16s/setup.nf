#!/usr/bin/env nextflow

process SETUP_SILVA_16S {
    publishDir path: "${params.databaseDir}/versions", mode: 'move', pattern: "*.txt"
    publishDir path: "${params.databaseDir}", mode: 'move', pattern: "silva_db"
    tag "SETUP_SILVA-16S"
    conda "${projectDir}/modules/silva-16s/environment.yaml"

    output:
        path "silva_db", emit: db
        path "silva-16s.txt", emit: version

    script:
    """
    wget -O silva.fasta.gz 'https://www.arb-silva.de/fileadmin/silva_databases/release_138_2/Exports/SILVA_138.2_SSURef_NR99_tax_silva.fasta.gz'
    gunzip silva.fasta.gz
    mkdir silva_db
    makeblastdb -in silva.fasta -dbtype nucl -out silva_db/silva_db
    date '+%Y-%m-%d %H:%M:%S' > silva-16s.txt
    echo 'Finished mamba environment setup.'
    """
}
