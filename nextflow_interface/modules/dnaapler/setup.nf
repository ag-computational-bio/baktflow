#!/usr/bin/env nextflow
nextflow.enable.dsl=2

// Define parameters for DNAapler
params.DNAAPLER_ENV_FILE = "${baseDir}/modules/dnaapler/environment.yaml"
params.DNAAPLER_ENV_PATH = "${baseDir}/../setup/conda_envs/dnaapler"

// Process to setup DNAapler
process SETUP_DNAAPLER {
    tag "SETUP_DNAAPLER"
    memory {4.GB * task.attempt}
    cpus (params.threads >= 2 ? 2 : params.threads)

    script:
    """
    echo 'Starting DNAapler environment setup...'
    echo "Conda environments path: ${params.DNAAPLER_ENV_PATH}"
    mamba env create -p ${params.DNAAPLER_ENV_PATH} -f ${params.DNAAPLER_ENV_FILE} -v
    echo 'Finished DNAapler environment setup.'
    """
}


    








