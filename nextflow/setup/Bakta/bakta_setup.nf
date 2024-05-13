// Load YAML file to access Conda-related parameters
params.config = loadYaml("config.yaml")

// Access Conda-related parameters
params.condaToolsBakta = params.config.condaToolsBakta
params.condaEnvBakta = params.config.condaEnvBakta

// Define Conda environment names based on the Conda tools
conda_bakta_name = params.condaToolsBakta.replace("=", "-").replace(":", "-").replace(" ", "-")

// Define Conda environments based on the defined Conda environment name
conda_bakta_env = file("${params.condadir}/${conda_bakta_name}").exists() ? "${params.condadir}/${conda_bakta_name}" : params.condaEnvBakta

// Process to create Conda environment if it doesn't exist
process Create_Conda_Env {
    label 'create_conda_env'

    // Only execute this process if the Conda environment doesn't exist
    when: !file(conda_bakta_env).exists()

    // Script to create Conda environment
    script:
    """
    # Create Conda environment
    conda create --name ${conda_bakta_env} ${params.condaToolsBakta} --yes || exit 1
    """
}

// Process to install Bakta using Conda environment
process BAKTA_Install {
    label 'install_bakta'

    // Define output directory for BAKTA installation
    output:
    path "${params.config.bakta_install_dir}" into bakta_install

    // Script to install BAKTA using Conda
    script:
    """
    # Activate Conda environment
    source activate ${conda_bakta_env} || conda activate ${conda_bakta_env}

    # Install BAKTA using Conda
    conda install --yes ${params.condaToolsBakta} || exit 1
    """
}

workflow {
    // Execute processes sequentially
    Create_Conda_Env() // Create Conda environment if necessary
    BAKTA_Install()    // Install Bakta
}
