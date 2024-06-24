#!/usr/bin/env nextflow
nextflow.enable.dsl=2

params.setupDir = "${baseDir}//bakta"
params.bakta_db_type = "light"  // Changed to a valid option
params.bakta_db = "${params.setupDir}/db"
params.bakta_save_as_tarball = false
params.publish_dir_mode = 'copy'
params.enable_conda = true

process installBakta {
    label 'install'
    tag "Install Bakta and Download DB"

    conda "${params.setupDir}/environment.yaml"

    publishDir params.bakta_db, mode: params.publish_dir_mode, overwrite: true

    output:
    path "bakta-${params.bakta_db_type}/*", emit: db, optional: true
    path "bakta-${params.bakta_db_type}.tar.gz", emit: db_tarball, optional: true
    path "*.{log,err}", emit: logs, optional: true
    path ".command.*", emit: nf_logs
    path "versions.yml", emit: versions

    script:
    """
    echo "Installing Bakta..."

    # Ensure the database directory exists
    

    # Create and activate the Conda environment
    conda env create --prefix ${params.setupDir}/bakta_env --file ${params.setupDir}/environment.yaml
    source activate ${params.setupDir}/bakta_env || conda activate ${params.setupDir}/bakta_env

    # Download the Bakta databases
    bakta_db download --type ${params.bakta_db_type} --output ${params.bakta_db}

    # Handle the downloaded database
    if [ '${params.bakta_save_as_tarball}' == 'true' ]; then
        tar -czf ${params.bakta_db}/bakta-${params.bakta_db_type}.tar.gz -C ${params.bakta_db} .
    else
        mv ${params.bakta_db}/bakta ${params.bakta_db}/bakta-${params.bakta_db_type}
    fi

    echo "Bakta Installation Summary:"
    echo "---------------------------------"
    echo "Installation Directory: ${params.bakta_db}"
    """
}

