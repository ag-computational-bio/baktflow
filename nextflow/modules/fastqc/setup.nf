params.FASTQC_ENV_FILE = "${baseDir}/modules/fastqc/environment.yaml"

process SETUP_FASTQC {
    tag "SETUP_FASTQC"

    conda "${params.FASTQC_ENV_FILE}"

    output:
    path "${params.CONDA_ENVS_PATH}/versions.yml", emit: versions, optional: true

    script:
    """
    echo "Installing FastQC using Conda..."
    fastqc_version=\$(conda list | grep -E '^fastqc ' | awk '{print \$2}')
    echo "FastQC version: \$fastqc_version" > ${params.CONDA_ENVS_PATH}/versions.yml
    echo "FastQC installation completed."
    """
}

    








