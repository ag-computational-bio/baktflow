#!/usr/bin/env

process PLING{
    tag "$meta.sample_id"
    publishDir "${params.output}/${meta.sample_id}/pling", mode: 'copy'
    conda "${projectDir}/modules/pling/environment.yaml"
    errorStrategy { (task.attempt <= 3) ? 'retry' : 'ignore' }
    memory { workflow.stubRun ? 64.MB : 8.GB * task.attempt }
    cpus { workflow.stubRun ? 1 : (params.threads >= 8 ? 8 : params.threads) }

    input:
        tuple val(meta), path(plasmid)

    output:
        tuple val(meta), path("results/*"), emit: results
        path("results/${meta.sample_id}.json.gz"), emit: json

    script:
    """
    ls *.fasta > plasmid_list.txt
    pling cluster align plasmid_list.txt results --cores ${task.cpus} --visualisation all
    rm -rf .snakemake/
    parse_pling.py results/all_plasmids_distances.tsv ${meta.sample_id}
    """

    stub:
    """
    mkdir results
    touch results/pling.log
    touch results/${meta.sample_id}.json.gz
    """


}