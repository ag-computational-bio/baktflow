#!/usr/bin/env nextflow

params.REPORT_SCRIPT = "$projectDir/modules/unicycler/report.py"

process UNICYCLER {
    tag "$meta.sample_id"
    publishDir "${params.output}/${meta.sample_id}/unicycler", mode: 'copy'
    conda "${projectDir}/modules/unicycler/environment.yaml"
    memory { workflow.stubRun ? 64.MB : 16.GB * task.attempt }
    cpus { workflow.stubRun ? 1 : (params.threads >= 8 ? 8 : params.threads) }
    
    input:
        tuple val(mode), val(meta), path(r1), path(r2), path(se), path(ont)

    output:
        tuple val(meta), path("${meta.sample_id}_assembly.fasta"), emit: scaffolds
        tuple val(meta), path("${meta.sample_id}_assembly.gfa"), emit: gfa
        tuple val(meta), path("${meta.sample_id}_unicycler.log"), emit: log


    script:
    if( mode == 'short' )
        """
        unicycler --short1 ${r1} --short2 ${r2} --unpaired ${se} --out ./ --keep 0 --threads ${task.cpus}

        # TODO compress output
        mv ./assembly.fasta ${meta.sample_id}_assembly.fasta
        mv ./assembly.gfa ${meta.sample_id}_assembly.gfa
        mv ./unicycler.log ${meta.sample_id}_unicycler.log

        python ${params.REPORT_SCRIPT} \\
        --fasta ${meta.sample_id}_assembly.fasta \\
        --log ${meta.sample_id}_unicycler.log \\
        --output ${params.output}/${meta.sample_id}/unicycler
        """
    else if( mode == 'hybrid' )
        """
        unicycler --short1 ${r1} --short2 ${r2} --unpaired ${se} --long ${ont} --out ./ --keep 0 --threads ${task.cpus}

        mv ./assembly.fasta ${meta.sample_id}_assembly.fasta
        mv ./assembly.gfa ${meta.sample_id}_assembly.gfa
        mv ./unicycler.log ${meta.sample_id}_unicycler.log

        python ${params.REPORT_SCRIPT} \\
        --fasta ${meta.sample_id}_assembly.fasta \\
        --log ${meta.sample_id}_unicycler.log \\
        --output ${params.output}/${meta.sample_id}/unicycler
        """
    else
        error "Invalid alignment mode: ${mode}"

    stub:
        """
        touch ${meta.sample_id}_assembly.fasta
        touch ${meta.sample_id}_assembly.gfa
        touch ${meta.sample_id}_unicycler.log
        """
}


