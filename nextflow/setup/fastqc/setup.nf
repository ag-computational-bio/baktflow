#!/usr/bin/env nextflow
nextflow.enable.dsl=2

params.setupDir = "${baseDir}/fastqc"  // Directory where Conda environment will be installed

process installFastqc {
    tag "Install FastQC"

    conda "${params.setupDir}/environment.yaml"  // Path to the Conda environment YAML file

    executor 'local'

    script:
    """
    echo "Creating Conda environment for FastQC in ${params.setupDir}"
    conda env create --prefix ${params.setupDir}/fastqc_env --file ${params.setupDir}/environment.yaml
    echo "FastQC installation completed"
    """
}


