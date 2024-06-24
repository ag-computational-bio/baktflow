#!/usr/bin/env nextflow
nextflow.enable.dsl=2

params.setupDir = "${baseDir}/fastp"  // Directory where Conda environment will be installed

process installFastp {
    tag "Install FastP"

    conda "${params.setupDir}/environment.yaml"  // Path to the FastP Conda environment YAML file

    executor 'local'

    script:
    """
    echo "Creating Conda environment for FastP in ${params.setupDir}"
    conda env create --prefix ${params.setupDir}/fastp_env --file ${params.setupDir}/environment.yaml
    echo "FastP installation completed"
    """
}



