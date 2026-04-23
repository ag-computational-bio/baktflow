#!/usr/bin/env nextflow

params.macsyfinder = "${params.modelsDir}"

process TXSSCAN{

     tag "$meta.sample_id"
     publishDir "${params.output}/${meta.sample_id}/macsyfinder", mode: 'copy'
     conda "${projectDir}/modules/macsyfinder/environment.yaml"
     memory { workflow.stubRun ? 64.MB : 8.GB * task.attempt }
     cpus { workflow.stubRun ? 1 : (params.threads >= 8 ? 8 : params.threads) }

    input:
        tuple val(meta), path(prot)

    output:
        tuple val(meta),  path("TXSScan/best_solution.tsv"), emit: best_solution, optional: true
        tuple val(meta),  path("TXSScan/all_best_solution.tsv"), emit: all_best_solution, optional: true
        tuple val(meta),  path("TXSScan/best_solution_loners.tsv"), emit: best_solution_loners, optional: true
        tuple val(meta),  path("TXSScan/best_solution_multisystems.tsv"), emit: best_solution_multisystems, optional: true
        tuple val(meta),  path("TXSScan/best_solution_summary.tsv"), emit: summary_tsv, optional: true
        tuple val(meta),  path("TXSScan/best_solution_summary.txt"), emit: summary_txt, optional: true
        tuple val(meta),  path("TXSScan/all_systems.tsv"), emit: all_systems_tsv, optional: true
        tuple val(meta),  path("TXSScan/all_systems.txt"), emit: all_systems_txt, optional: true
        tuple val(meta),  path("TXSScan/all_best_solutions.tsv"), emit: all_best_solutions, optional: true
        tuple val(meta),  path("TXSScan/macsyfinder.log"), emit: log
        tuple val(meta),  path("TXSScan/hmmer_results/"), emit: hmmer, optional: true

    script:
    """
    macsyfinder --db-type ordered_replicon --sequence-db ${prot} --models-dir ${params.macsyfinder} --models TXSScan all --mute -o TXSScan -w ${task.cpus}
    """

    stub:
    """
    mkdir TXSScan
    touch TXSScan/macsyfinder.log
    """
}