#!/usr/bin/env nextflow

params.pmlst_db = "${params.databaseDir}/pmlst_db"

process PMLST{
        tag "$meta.sample_id"
        publishDir "${params.output}/${meta.sample_id}/pmlst", mode: 'copy'
        conda "${projectDir}/modules/pmlst/environment.yaml"
        memory { workflow.stubRun ? 64.MB : 8.GB * task.attempt }
        cpus { workflow.stubRun ? 1 : (params.threads >= 8 ? 8 : params.threads) }

        input:
                tuple val(meta), path(assembly)

        output:
                tuple val(meta), path("*/data.json"), emit: json
                tuple val(meta), path("*/Hit_in_genome_seq.fsa"), emit: git_genome
                tuple val(meta), path("*/pMLST_allele_seq.fsa"), emit: pmlst_allele
                tuple val(meta), path("*/results_tab.tsv"), emit: results_tab
                tuple val(meta), path("*/results.txt"), emit: results_txt


        script:
        def schema_list = ['incf', 'incf', 'inchi1', 'inchi2', 'inci1', 'incn', 'pbssb1-family', 'shigella'].join(' ')
        """
        for schema in ${schema_list}; do
                mkdir -p \$schema
                pmlst.py -i ${assembly} -o \$schema -s \$schema -p ${params.pmlst_db} -x -q
        done
        """

        stub:
        """
        mkdir -p incf
        touch incf/data.json
        touch incf/Hit_in_genome_seq.fsa
        touch incf/pMLST_allele_seq.fsa
        touch incf/results_tab.tsv
        touch incf/results.txt
        """

}