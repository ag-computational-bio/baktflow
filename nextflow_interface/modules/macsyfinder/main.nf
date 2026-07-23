#!/usr/bin/env nextflow

process CASFINDER{
    tag "$meta.sample_id"
    publishDir "${params.output}/${meta.sample_id}/macsyfinder", mode: 'copy'
    conda "${projectDir}/modules/macsyfinder/environment.yaml"
    memory { workflow.stubRun ? 64.MB : 256.MB * task.attempt }
    cpus { workflow.stubRun ? 1 : (params.threads >= 8 ? 8 : params.threads) }

    input:
        tuple val(meta), path(prot)

    output:
        tuple val(meta),  path("CasFinder/best_solution.tsv"), emit: best_solution, optional: true
        tuple val(meta),  path("CasFinder/all_best_solution.tsv"), emit: all_best_solution, optional: true
        tuple val(meta),  path("CasFinder/best_solution_loners.tsv"), emit: best_solution_loners, optional: true
        tuple val(meta),  path("CasFinder/best_solution_multisystems.tsv"), emit: best_solution_multisystems, optional: true
        tuple val(meta),  path("CasFinder/best_solution_summary.tsv"), emit: summary_tsv, optional: true
        tuple val(meta),  path("CasFinder/best_solution_summary.txt"), emit: summary_txt, optional: true
        tuple val(meta),  path("CasFinder/all_systems.tsv"), emit: all_systems_tsv, optional: true
        tuple val(meta),  path("CasFinder/all_systems.txt"), emit: all_systems_txt, optional: true
        tuple val(meta),  path("CasFinder/all_best_solutions.tsv"), emit: all_best_solutions, optional: true
        tuple val(meta),  path("CasFinder/macsyfinder.log"), emit: log
        tuple val(meta),  path("CasFinder/hmmer_results/"), emit: hmmer, optional: true
        path("CasFinder/${meta.sample_id}.json.gz"), emit:json

    script:
    """
    macsyfinder --db-type ordered_replicon --sequence-db ${prot} --models-dir ${params.databaseDir}/macsyfinder --models CASFinder all --mute -o CasFinder -w ${task.cpus}
    parse_macsyfinder.py CasFinder/best_solution.tsv ${meta.sample_id} CasFinder
    """

    stub:
    """
    mkdir CasFinder
    touch CasFinder/macsyfinder.log
    touch CasFinder/${meta.sample_id}.json.gz
    """
}

process CONJSCAN{
    tag "$meta.sample_id"
    publishDir "${params.output}/${meta.sample_id}/macsyfinder", mode: 'copy'
    conda "${projectDir}/modules/macsyfinder/environment.yaml"
    memory { workflow.stubRun ? 64.MB : 256.MB * task.attempt }
    cpus { workflow.stubRun ? 1 : (params.threads >= 8 ? 8 : params.threads) }

    input:
        tuple val(meta), path(prot)

    output:
        tuple val(meta),  path("CONJScan/best_solution.tsv"), emit: best_solution, optional: true
        tuple val(meta),  path("CONJScan/all_best_solution.tsv"), emit: all_best_solution, optional: true
        tuple val(meta),  path("CONJScan/best_solution_loners.tsv"), emit: best_solution_loners, optional: true
        tuple val(meta),  path("CONJScan/best_solution_multisystems.tsv"), emit: best_solution_multisystems, optional: true
        tuple val(meta),  path("CONJScan/best_solution_summary.tsv"), emit: summary_tsv, optional: true
        tuple val(meta),  path("CONJScan/best_solution_summary.txt"), emit: summary_txt, optional: true
        tuple val(meta),  path("CONJScan/all_systems.tsv"), emit: all_systems_tsv, optional: true
        tuple val(meta),  path("CONJScan/all_systems.txt"), emit: all_systems_txt, optional: true
        tuple val(meta),  path("CONJScan/all_best_solutions.tsv"), emit: all_best_solutions, optional: true
        tuple val(meta),  path("CONJScan/macsyfinder.log"), emit: log
        tuple val(meta),  path("CONJScan/hmmer_results/"), emit: hmmer, optional: true
        path("CONJScan/${meta.sample_id}.json.gz"), emit: json

    script:
    """
    macsyfinder --db-type ordered_replicon --sequence-db ${prot} --models-dir ${params.databaseDir}/macsyfinder --models CONJScan all --mute -o CONJScan -w ${task.cpus}
    parse_macsyfinder.py CONJScan/best_solution.tsv ${meta.sample_id} CONJScan
    """

    stub:
    """
    mkdir CONJScan
    touch CONJScan/macsyfinder.log
    touch CONJScan/${meta.sample_id}.json.gz
    """
}

process TXSSCAN{
    tag "$meta.sample_id"
    publishDir "${params.output}/${meta.sample_id}/macsyfinder", mode: 'copy'
    conda "${projectDir}/modules/macsyfinder/environment.yaml"
    memory { workflow.stubRun ? 64.MB : 256.MB * task.attempt }
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
        path("TXSScan/${meta.sample_id}.json.gz"), emit: json

    script:
    """
    macsyfinder --db-type ordered_replicon --sequence-db ${prot} --models-dir ${params.databaseDir}/macsyfinder --models TXSScan all --mute -o TXSScan -w ${task.cpus}
    parse_macsyfinder.py TXSScan/best_solution.tsv ${meta.sample_id} TXSScan
    """

    stub:
    """
    mkdir TXSScan
    touch TXSScan/macsyfinder.log
    touch TXSScan/${meta.sample_id}.json.gz
    """
}
