#!/usr/bin/env nextflow


process UNICYCLER {
    tag "$meta.sample_id"
    publishDir "${params.output}/${meta.sample_id}/unicycler", mode: 'copy'
    conda "${projectDir}/modules/unicycler/environment.yaml"
    errorStrategy { (task.attempt <= 3) ? 'retry' : 'ignore' }
    scratch true
    memory { workflow.stubRun ? 64.MB : 8.GB * task.attempt }
    cpus { workflow.stubRun ? 1 : (params.threads >= 8 ? 8 : params.threads) }
    
    input:
        tuple val(meta), path(r1), path(r2), path(se), path(ont)

    output:
        tuple val(meta), path("${meta.sample_id}_assembly.fasta"), emit: scaffolds
        tuple val(meta), path("${meta.sample_id}_assembly.gfa"), emit: gfa
        tuple val(meta), path("${meta.sample_id}_unicycler.log"), emit: log
        tuple val(meta), val('unicycler'), path("${meta.sample_id}_assembly.fasta"), emit: report

    // TODO --existing_long_read_assembly for hybrid?
    script:
    if( meta.sample_type == 'short' )
        """
        if [[ \$(zgrep -c '+' ${se}) -gt 0 ]]; then
            unicycler --short1 ${r1} --short2 ${r2} --unpaired ${se} --out ./ --keep 0 --threads ${task.cpus}
        else
            unicycler --short1 ${r1} --short2 ${r2} --out ./ --keep 0 --threads ${task.cpus}
        fi

        mv ./assembly.fasta ${meta.sample_id}_assembly.fasta
        mv ./assembly.gfa ${meta.sample_id}_assembly.gfa
        mv ./unicycler.log ${meta.sample_id}_unicycler.log
        """
    else if( meta.sample_type == 'hybrid' )
        """
        if [[ \$(zgrep -c '+' ${se}) -gt 0 ]]; then
            unicycler --short1 ${r1} --short2 ${r2} --unpaired ${se} --long ${ont} --out ./ --keep 0 --threads ${task.cpus}
        else
            unicycler --short1 ${r1} --short2 ${r2} --long ${ont} --out ./ --keep 0 --threads ${task.cpus}
        fi

        mv ./assembly.fasta ${meta.sample_id}_assembly.fasta
        mv ./assembly.gfa ${meta.sample_id}_assembly.gfa
        mv ./unicycler.log ${meta.sample_id}_unicycler.log
        """
    else
        error "Invalid alignment mode: ${meta.sample_type}"

    stub:
        """
        touch ${meta.sample_id}_assembly.fasta
        touch ${meta.sample_id}_assembly.gfa
        touch ${meta.sample_id}_unicycler.log
        """
}
