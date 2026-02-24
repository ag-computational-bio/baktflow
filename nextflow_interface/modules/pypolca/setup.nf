#!/usr/bin/env nextflow
nextflow.enable.dsl=2

// Process to setup Pypolca
process SETUP_PYPOLCA {
    tag "SETUP_PYPOLCA"

    conda "${projectDir}/modules/pypolca/environment.yaml"
    if ( "${workflow.stubRun}" == "false" ) {
        cpus (params.threads >= 2 ? 2 : params.threads)
        memory {4.GB * task.attempt}
    }

    script:
    """
    echo 'Finished Pypolca environment setup.'
    """
}
