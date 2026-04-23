#!/usr/bin/env nextflow

process SETUP_DIAMOND {
    publishDir path: "${params.databaseDir}", mode: 'move'
    tag "SETUP_DIAMOND"
    conda "${projectDir}/modules/diamond/environment.yaml"

    output:
        path "vfdb.dmnd", emit: db

    script:
    """
    wget -O vfdb https://www.mgc.ac.cn/VFs/Down/VFDB_setB_pro.fas.gz
    diamond makedb --in vfdb -d vfdb.dmnd
    echo 'Finished mamba environment setup.'
    """
}
