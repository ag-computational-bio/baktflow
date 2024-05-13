// Define default output directories for FastQC and Bakta installations
params.default_fastqc_install_dir = "/path/to/default/fastqc/installation"
params.default_bakta_install_dir = "/path/to/default/bakta/installation"

// Path to the installation scripts for FastQC and Bakta
params.fastqc_script = "/path/to/fastqc_install.nf"
params.bakta_script = "/path/to/bakta_install.nf"

// Define a function to display installation progress
def displayProgress(processName) {
    """
    println "Installing ${processName}..."
    """
}

// Function to handle errors
def handleErrors(processName, errorMessage) {
    """
    println "Error occurred during ${processName} installation:"
    println "---------------------------------"
    println errorMessage
    """
}

// Run the installation script for FastQC
process FastQC_Installation {
    label 'install_fastqc'
    script:
    """
    nextflow ${params.fastqc_script} --custom_fastqc_install_dir ${params.default_fastqc_install_dir}
    """
    // Display progress
    script:
    """
    ${displayProgress('FastQC')}
    """
    // Output summary information
    script:
    """
    println "FastQC Installation Summary:"
    println "---------------------------------"
    println "Installation Directory: ${params.default_fastqc_install_dir}"
    """
    // Error handling
    errorStrategy { task.exitStatus != 0 ? 'ignore' : 'terminate' }
    script:
    """
    if (task.exitStatus != 0) {
        handleErrors('FastQC', task.errorMessage)
    }
    """
}

// Run the installation script for Bakta
process Bakta_Installation {
    label 'install_bakta'
    script:
    """
    nextflow ${params.bakta_script} --custom_bakta_install_dir ${params.default_bakta_install_dir}
    """
    // Display progress
    script:
    """
    ${displayProgress('Bakta')}
    """
    // Output summary information
    script:
    """
    println "Bakta Installation Summary:"
    println "---------------------------------"
    println "Installation Directory: ${params.default_bakta_install_dir}"
    """
    // Error handling
    errorStrategy { task.exitStatus != 0 ? 'ignore' : 'terminate' }
    script:
    """
    if (task.exitStatus != 0) {
        handleErrors('Bakta', task.errorMessage)
    }
    """
}


