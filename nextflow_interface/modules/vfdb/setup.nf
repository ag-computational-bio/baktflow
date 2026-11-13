#!/usr/bin/env nextflow

process SETUP_VFDB {
    publishDir path: "${params.databaseDir}/versions", mode: 'move', pattern: "*.txt"
    publishDir path: "${params.databaseDir}", mode: 'move', pattern: "vfdb.dmnd"
    tag "SETUP_VFDB"
    conda "${projectDir}/modules/vfdb/environment.yaml"

    output:
        path "vfdb.dmnd", emit: db
        path "vfdb.txt", emit: version

    script:
    """
    wget -O vfdb https://www.mgc.ac.cn/VFs/Down/VFDB_setB_pro.fas.gz
    diamond makedb --in vfdb -d vfdb.dmnd
    date '+%Y-%m-%d %H:%M:%S' > vfdb.txt
    echo 'Finished mamba environment setup.'
    """
}
