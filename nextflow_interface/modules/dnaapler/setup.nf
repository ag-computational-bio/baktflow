#!/usr/bin/env nextflow

process SETUP_DNAAPLER {
    tag "SETUP_DNAAPLER"
    conda "${projectDir}/modules/dnaapler/environment.yaml"

    script:
    """
    echo 'Finished DNAapler environment setup.'
    """
}
