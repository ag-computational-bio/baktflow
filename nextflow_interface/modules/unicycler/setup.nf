#!/usr/bin/env nextflow
nextflow.enable.dsl=2

// Process to setup Unicycler
process SETUP_UNICYCLER {
    tag "SETUP_UNICYCLER"

    conda "${projectDir}/modules/unicycler/environment.yaml"

    script:
    """
    echo 'Finished Unicycler environment setup.'
    """
}



    








