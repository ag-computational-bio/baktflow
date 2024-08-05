#!/usr/bin/env nextflow

nextflow.enable.dsl=2
// Define parameters with default values
params.CONDA_ENV_DIR = params.CONDA_ENV_DIR ?: "./setup/conda_envs"

// Function to find the Conda environment path dynamically
def findCondaEnvPath(String envDir, String pattern) {
    def envPath = new File(envDir).listFiles().find { it.isDirectory() && it.name.startsWith(pattern) }
    return envPath ? envPath.absolutePath : null
}

// Get the Conda environment path for fastqc
params.CONDA_ENV_PATH = findCondaEnvPath(params.CONDA_ENV_DIR, 'fastqc-')

if (!params.CONDA_ENV_PATH) {
    error "Conda environment matching pattern 'fastqc' not found in directory '${params.CONDA_ENV_DIR}'. Please ensure it is installed."
}

// Process to run FastQC analysis
process FASTQC_ANALYSIS {
    tag { id }

    conda "${params.CONDA_ENV_PATH}"

    input:
    tuple val(id), val(type), path(files)

    output:
    tuple val(id),path("${id}/fastqc")

    publishDir "${params.OUTPUT_DIR}", mode: 'copy'

    script:
    """
    mkdir -p ${id}/fastqc
    fastqc ${files.join(' ')} -o ${id}/fastqc
    """
}

// Process to get version information
process getVersionInfo {
    tag { id }

    input:
    tuple val(id),path(fastqc_dir)

    output:
    path("versions_${id}_fastqc.yml")

    publishDir "${params.OUTPUT_DIR}/${id}/fastqc", mode: 'copy'

    script:
    """
    cat <<-END_VERSIONS > versions_${id}_fastqc.yml
    "${task.process}":
        fastqc: \$( fastqc --version | sed -e "s/FastQC v//g" )
    END_VERSIONS
    """
}













