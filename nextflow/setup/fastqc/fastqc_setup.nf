// Load YAML file to access Conda-related parameters
params.config = loadYaml("config.yaml")

// Access Conda-related parameters for FastQC
params.condaToolsFastQC = params.config.condaToolsFastQC
params.condaEnvFastQC = params.config.condaEnvFastQC

// Define Conda environment names for FastQC
conda_fastqc_name = params.condaToolsFastQC.replace("=", "-").replace(":", "-").replace(" ", "-")

// Define Conda environment for FastQC
conda_fastqc_env = file("${params.condadir}/${conda_fastqc_name}").exists() ? "${params.condadir}/${conda_fastqc_name}" : params.condaEnvFastQC

// Process to create Conda environment for FastQC if it doesn't exist
process Create_Conda_Env_FastQC {
    label 'create_conda_env_fastqc'

    // Only execute this process if the Conda environment for FastQC doesn't exist
    when: !file(conda_fastqc_env).exists()

    // Script to create Conda environment for FastQC
    script:
    """
    # Create Conda environment for FastQC
    conda create --name ${conda_fastqc_env} ${params.condaToolsFastQC} --yes || exit 1
    """
}

// Process to install FastQC using Conda environment
process FASTQC_Install {
    label 'install_fastqc'

    // Define output directory for FastQC installation
    output:
    path "${params.config.fastqc_install_dir}" into fastqc_install

    // Script to install FastQC using Conda
    script:
    """
    # Activate Conda environment for FastQC
    source activate ${conda_fastqc_env} || conda activate ${conda_fastqc_env}

    # Install FastQC using Conda
    conda install --yes ${params.condaToolsFastQC} || exit 1
    """
}
