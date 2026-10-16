#!/usr/bin/env nextflow

process METABINNER {
    tag "$meta.sample_id"
    publishDir "${params.output}/${meta.sample_id}/metabinner", pattern: "*.log", mode: 'copy'
    conda "${projectDir}/modules/metabinner/environment.yaml"
    memory { workflow.stubRun ? 64.MB : 48.GB * task.attempt }
    cpus { workflow.stubRun ? 1 : (params.threads >= 4 ? 4 : params.threads) }

    input:
        tuple val(meta), path("${meta.sample_id}.fasta"), path(bai), path(bam)

    output:
        tuple val(meta), path("metabinner_bins"), emit: bins
        path("result.log"), emit: log

    script:
    def lower = 999
    """
    jgi_summarize_bam_contig_depths --outputDepth depth.txt --noIntraDepthVariance ${bam}
    awk '{if (\$2>${lower}) print \$0 }' depth.txt | cut -f 1,4 > coverage_profile.tsv
    gen_kmer.py ${meta.sample_id}.fasta ${lower} 4

    METABINNERDIR=\$(which run_metabinner.sh | sed 's/\\/run_metabinner.sh//')

    run_metabinner.sh -a \$(realpath ${meta.sample_id}.fasta) -o \$(realpath ./metabin) -d \$(realpath coverage_profile.tsv) \
    -k \$(realpath ${meta.sample_id}_kmer_4_f${lower}.csv) -p \$METABINNERDIR -t ${task.cpus}

    mv metabin/metabinner_res/ensemble_res/greedy_cont_weight_3_mincomp_50.0_maxcont_15.0_bins/ensemble_3logtrans/addrefined2and3comps/greedy_cont_weight_3_mincomp_50.0_maxcont_15.0_bins ./metabinner_bins
    mv metabin/metabinner_res/post_result.log ./result.log
    """

    stub:
    """
    touch ${meta.sample_id}_depleted.fastq.gz
    """
}
