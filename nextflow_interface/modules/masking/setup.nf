#!/usr/bin/env nextflow

process SETUP_MASKING{
        tag "SETUP_MASKING"
        conda "${projectDir}/modules/masking/environment.yaml"

        script:
        """
        echo 'Finished masking environment setup.'
        """
}