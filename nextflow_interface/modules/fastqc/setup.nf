#!/usr/bin/env nextflow
nextflow.enable.dsl=2

process SETUP_FASTQC {
    tag "SETUP_FASTQC"

    conda "${projectDir}/modules/fastqc/environment.yaml"
    if ( "${workflow.stubRun}" == "false" ) {
        cpus (params.threads >= 2 ? 2 : params.threads)
        memory {4.GB * task.attempt}
    }

    script:
    """
    echo 'Finished mamba environment setup.'
    """
}








