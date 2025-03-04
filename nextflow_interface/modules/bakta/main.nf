#!/usr/bin/env nextflow
nextflow.enable.dsl=2

// Define parameters with default values
params.CONDA_ENV_DIR = "$baseDir/../setup/conda_envs"
params.CONDA_ENV_PATH = "${params.CONDA_ENV_DIR}/bakta"
params.DATABASE_PATH = "$baseDir/../setup/databases/bakta/bakta_db/db-light"
params.OUTPUT_DIR = "$baseDir/../output"  


process BAKTA {
    input:
    tuple val(meta), path(assembly)

    output:
    tuple val(meta), path("${meta.sample_id}.embl"), emit: embl
    tuple val(meta), path("${meta.sample_id}.faa"), emit: faa
    tuple val(meta), path("${meta.sample_id}.ffn"), emit: ffn
    tuple val(meta), path("${meta.sample_id}.fna"), emit: fna
    tuple val(meta), path("${meta.sample_id}.gbff"), emit: gbff
    tuple val(meta), path("${meta.sample_id}.gff3"), emit: gff
    tuple val(meta), path("${meta.sample_id}.hypotheticals.tsv"), emit: hypotheticals_tsv
    tuple val(meta), path("${meta.sample_id}.hypotheticals.faa"), emit: hypotheticals_faa
    tuple val(meta), path("${meta.sample_id}.tsv"), emit: tsv
    tuple val(meta), path("${meta.sample_id}.txt"), emit: txt
   

    publishDir "${params.OUTPUT_DIR}/${meta.sample_id}/bakta", mode: 'copy'

    conda "${params.CONDA_ENV_PATH}"
    errorStrategy { task.attempt <= 3 ? 'retry' : 'ignore' }  // Retry up to 3 times, then ignore
    maxRetries 3  // Ensure maxRetries is set to allow up to 3 retries 
    // Resource allocation
    cpus 8
    memory '16GB' 
    
    script:
    """
    mkdir -p bakta_output

    echo "Running Bakta for sample: ${meta.sample_id}, assembly: ${assembly}"

    # Run Bakta
    bakta \\
        --db "${params.DATABASE_PATH}" \\
        --output bakta_output \\
        --prefix ${meta.sample_id} \\
        --threads $task.cpus \\
        --force \\
        ${assembly}

    # Check if Bakta run was successful
    if [ \$? -ne 0 ]; then
        echo "Bakta annotation failed for sample: ${meta.sample_id}"
        exit 1
    fi

    # Move files to the correct output
    mv bakta_output/${meta.sample_id}.embl ${meta.sample_id}.embl
    mv bakta_output/${meta.sample_id}.faa ${meta.sample_id}.faa
    mv bakta_output/${meta.sample_id}.ffn ${meta.sample_id}.ffn
    mv bakta_output/${meta.sample_id}.fna ${meta.sample_id}.fna
    mv bakta_output/${meta.sample_id}.gbff ${meta.sample_id}.gbff
    mv bakta_output/${meta.sample_id}.gff3 ${meta.sample_id}.gff3
    mv bakta_output/${meta.sample_id}.hypotheticals.tsv ${meta.sample_id}.hypotheticals.tsv
    mv bakta_output/${meta.sample_id}.hypotheticals.faa ${meta.sample_id}.hypotheticals.faa
    mv bakta_output/${meta.sample_id}.tsv ${meta.sample_id}.tsv
    mv bakta_output/${meta.sample_id}.txt ${meta.sample_id}.txt

    echo "Bakta run completed for sample: ${meta.sample_id}"
    """
}



























