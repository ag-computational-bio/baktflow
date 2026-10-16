#!/usr/bin/env nextflow

process METAWRAP {
    tag "$meta.sample_id"
    publishDir "${params.output}/${meta.sample_id}/metawrap", pattern: "*.png", mode: 'copy'
    conda "${projectDir}/modules/metawrap/environment.yaml"
    memory { workflow.stubRun ? 64.MB : 192.GB * task.attempt }
    cpus { workflow.stubRun ? 1 : (params.threads >= 8 ? 8 : params.threads) }
    scratch true

    input:
        tuple val(meta), path(metabinner), path(semibin), path(metacat)

    output:
        tuple val(meta), path("bin.*.fna"), emit: bins
        path("*.png"), emit: figures

    script:
    """
    MEM=\$(echo $task.memory | awk '{print \$1}')
    metaWRAP bin_refinement -o refinded_bins -t ${task.cpus} -m \$MEM -A ${metabinner} -B ${semibin} -C ${metacat}
    mv refinded_bins/metawrap_*_bins/*.fa ./
    mv refinded_bins/figures/*.png ./
    rm -r refinded_bins
    find . -name "*.fa" -exec sh -c 'mv "\$1" "\${1%.fa}.fna"' _ {} \\;
    """

    stub:
    """
    touch ${meta.sample_id}_depleted.fastq.gz
    """
}
