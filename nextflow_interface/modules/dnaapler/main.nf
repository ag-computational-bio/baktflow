#!/usr/bin/env nextflow

process DNAAPLER {
    publishDir "${params.output}/${meta.sample_id}/dnaapler", mode: 'copy'
    conda "${projectDir}/modules/dnaapler/environment.yaml"
    memory { workflow.stubRun ? 64.MB : 2.GB * task.attempt }
    cpus { workflow.stubRun ? 1 : (params.threads >= 8 ? 8 : params.threads) }

    input:
        tuple val(meta), path(input_fasta)

    output:
        tuple val(meta), path("${meta.sample_id}_reoriented.fasta"), emit: assembly
        path("${meta.sample_id}.json.gz"), emit: json

    script:
    """
    dnaapler all --prefix ${meta.sample_id} --input ${input_fasta} --output out --threads $task.cpus

    mv out/${meta.sample_id}_reoriented.fasta ${meta.sample_id}_reoriented.fasta
    rm -r out

    parse_assembly.py ${meta.sample_id}_reoriented.fasta ${meta.sample_id} dnaapler
    """

    stub:
    """
    touch ${meta.sample_id}_reoriented.fasta
    touch ${meta.sample_id}.json.gz
    """
}
