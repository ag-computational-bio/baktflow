#!/usr/bin/env nextflow

process MASKING {
    tag "$meta.sample_id"
    publishDir "${params.output}/${meta.sample_id}/masking", pattern: "*.tsv", mode: 'copy'
    conda "${projectDir}/modules/masking/environment.yaml"
    memory { workflow.stubRun ? 64.MB : 4.GB * task.attempt }
    cpus { workflow.stubRun ? 1 : (params.threads >= 8 ? 8 : params.threads) }

    input:
        tuple val(meta), path(assembly), val(organism), path(r1), path(r2), path(se), path(long_reads)

    output:
        tuple val(meta), path("${meta.sample_id}.masked.fasta"), val(organism), emit: assembly
        tuple val(meta), val('masking'), path("${meta.sample_id}.masked.fasta"), emit: report
        path("${meta.sample_id}_alpaqa.tsv"), emit: log

    script:
    // --ambig ?
    if ( meta.sample_type == 'short' )
        """
        minibwa index ${assembly}
        minibwa map -t $task.cpus ${assembly} ${r1} ${r2} | samtools sort - -@ ${task.cpus} -o alignments_pe.bam
        if [ -s ${se} ]; then
            minibwa map -t $task.cpus ${assembly} ${se} | samtools sort - -@ ${task.cpus} -o alignments_se.bam
            samtools merge -@ ${task.cpus} alignments_merged.bam alignments_pe.bam alignments_se.bam
        else
            mv alignments_pe.bam alignments_merged.bam
        fi

        samtools index -@ ${task.cpus} alignments_merged.bam
        samtools consensus -@ ${task.cpus} -f fastq -X hiseq -a -T ${assembly} alignments_merged.bam -o ${meta.sample_id}_assembly.fastq

        alpaqa -i ${meta.sample_id}_assembly.fastq -o ${meta.sample_id}_alpaqa.tsv -t ${task.cpus}

        # Check LQB/Mbp and conditionally run masking
        lqb_val=\$(awk 'NR>1 {print \$4}' ${meta.sample_id}_alpaqa.tsv)

        # Use awk to compare floating point numbers (returns 1 for True, 0 for False)
        do_mask=\$(awk -v val="\$lqb_val" -v limit="${params.min_lqb_mb}" 'BEGIN {print (val >= limit) ? 1 : 0}')

        if [ "\$lqb_val" != "Low" ] && [ "\$do_mask" -eq 1 ]; then
            echo "Sample ${meta.sample_id}: LQB/Mbp (\$lqb_val) >= ${params.min_lqb_mb}. Masking with Q<${params.mask_threshold}..."
            cat ${meta.sample_id}_assembly.fastq | masking.py ${params.mask_threshold} > ${meta.sample_id}.masked.fasta
        else
            echo "Sample ${meta.sample_id}: LQB/Mbp (\$lqb_val) < ${params.min_lqb_mb}. No masking needed."
            cp ${assembly} ${meta.sample_id}.masked.fasta
        fi

        rm *.l2b *.mbw *.bam *.bai *.fai
        """
    else if ( meta.sample_type == 'long' ) // Uses Medaka FASTQ
        """
        alpaqa -i ${long_reads} -o ${meta.sample_id}_alpaqa.tsv -t ${task.cpus}

        # Check LQB/Mbp and conditionally run masking
        lqb_val=\$(awk 'NR>1 {print \$4}' ${meta.sample_id}_alpaqa.tsv)

        # Use awk to compare floating point numbers (returns 1 for True, 0 for False)
        do_mask=\$(awk -v val="\$lqb_val" -v limit="${params.min_lqb_mb}" 'BEGIN {print (val >= limit) ? 1 : 0}')

        if [ "\$lqb_val" != "Low" ] && [ "\$do_mask" -eq 1 ]; then
            echo "Sample ${meta.sample_id}: LQB/Mbp (\$lqb_val) >= ${params.min_lqb_mb}. Masking with Q<${params.mask_threshold}..."
            cat ${long_reads} | masking.py ${params.mask_threshold} > ${meta.sample_id}.masked.fasta
        else
            echo "Sample ${meta.sample_id}: LQB/Mbp (\$lqb_val) < ${params.min_lqb_mb}. No masking needed."
            cp ${assembly} ${meta.sample_id}.masked.fasta
        fi
        """
    else if ( meta.sample_type == 'hybrid' )
        """
        # Map and get quality fastq for short reads
        minibwa index ${assembly}
        minibwa map -t $task.cpus ${assembly} ${r1} ${r2} | samtools sort - -@ ${task.cpus} -o alignments_pe.bam
        if [ -s ${se} ]; then
            minibwa map -t $task.cpus ${assembly} ${se} | samtools sort - -@ ${task.cpus} -o alignments_se.bam
            samtools merge -@ ${task.cpus} alignments_short_merged.bam alignments_pe.bam alignments_se.bam
        else
            mv alignments_pe.bam alignments_short_merged.bam
        fi

        samtools index -@ ${task.cpus} alignments_short_merged.bam
        samtools consensus -@ ${task.cpus} -f fastq -X hiseq alignments_short_merged.bam -o ${meta.sample_id}_mapped_quality.fastq

        # Map and get quality fastq for long reads
        minimap2 -t ${task.cpus} -a -x map-ont ${assembly} ${long_reads} | samtools sort - -@ ${task.cpus} -o alignments_long.bam

        samtools index -@ ${task.cpus} alignments_long.bam
        samtools consensus -@ ${task.cpus} -f fastq -X ${params.calibration} alignments_long.bam >> ${meta.sample_id}_mapped_quality.fastq

        # Remap and combine quality fastq
        minimap2 -t ${task.cpus} -a ${assembly} ${meta.sample_id}_mapped_quality.fastq | samtools sort - -@ ${task.cpus} -o alignments_combined.bam

        samtools index -@ ${task.cpus} alignments_combined.bam
        samtools consensus -@ ${task.cpus} -m simple -q --no-use-MQ -f fastq -a -T ${assembly} alignments_combined.bam -o ${meta.sample_id}_assembly.fastq

        alpaqa -i ${meta.sample_id}_assembly.fastq -o ${meta.sample_id}_alpaqa.tsv -t ${task.cpus}

        # Check LQB/Mbp and conditionally run masking
        lqb_val=\$(awk 'NR>1 {print \$4}' ${meta.sample_id}_alpaqa.tsv)

        # Use awk to compare floating point numbers (returns 1 for True, 0 for False)
        do_mask=\$(awk -v val="\$lqb_val" -v limit="${params.min_lqb_mb}" 'BEGIN {print (val >= limit) ? 1 : 0}')

        if [ "\$lqb_val" != "Low" ] && [ "\$do_mask" -eq 1 ]; then
            echo "Sample ${meta.sample_id}: LQB/Mbp (\$lqb_val) >= ${params.min_lqb_mb}. Masking with Q<${params.mask_threshold}..."
            cat ${meta.sample_id}_assembly.fastq | masking.py ${params.mask_threshold} > ${meta.sample_id}.masked.fasta
        else
            echo "Sample ${meta.sample_id}: LQB/Mbp (\$lqb_val) < ${params.min_lqb_mb}. No masking needed."
            cp ${assembly} ${meta.sample_id}.masked.fasta
        fi

        rm *.l2b *.mbw *.bam *.bai *.fai
        """
    else
        error "Invalid alignment mode: ${meta.sample_type}"

    stub:
    """
    touch ${meta.sample_id}.masked.fasta
    """
}