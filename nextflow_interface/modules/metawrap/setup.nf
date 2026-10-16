#!/usr/bin/env nextflow

process SETUP_METAWRAP {
    tag "SETUP_METAWRAP"
    conda "${projectDir}/modules/metawrap/environment.yaml"

    script:
    """
    mkdir checkm1db
    cd checkm1db
    wget https://zenodo.org/records/7401545/files/checkm_data_2015_01_16.tar.gz
        tar -xzf checkm_data_2015_01_16.tar.gz
    rm checkm_data_2015_01_16.tar.gz
    cd ..
    mv checkm1db ${params.databaseDir}
    checkm data setRoot ${params.databaseDir}/checkm1db
    """
}
