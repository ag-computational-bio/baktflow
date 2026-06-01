#!/usr/bin/env nextflow

process SETUP_VFDB {
    publishDir path: "${params.databaseDir}", mode: 'move'
    tag "SETUP_VFDB"
    conda "${projectDir}/modules/vfdb/environment.yaml"

    output:
        path "vfdb.dmnd", emit: db

    script:
    """
    wget -O vfdb https://www.mgc.ac.cn/VFs/Down/VFDB_setB_pro.fas.gz
    diamond makedb --in vfdb -d vfdb.dmnd
    echo 'Finished mamba environment setup.'
    """
}
