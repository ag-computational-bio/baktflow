#!/usr/bin/env nextflow

process GENOMESTATS {
    tag "$meta.sample_id"
    conda "${projectDir}/modules/genomestats/environment.yaml"
    publishDir "${params.output}/${meta.sample_id}/genomestats", pattern: "*.log", mode: 'copy'
    memory { workflow.stubRun ? 1.GB : 4.GB * task.attempt }
    cpus { workflow.stubRun ? 1 : (params.threads >= 4 ? 4 : params.threads) }

    input:
        tuple val(meta), path(r1), path(r2), path(se), path(long_reads)

    output:
        tuple val(meta), env('GENOMESIZE'), env('COVERAGE'), path(r1), path(r2), path(se), emit: short_genome_size
        tuple val(meta), env('GENOMESIZE'), env('COVERAGE'), path(long_reads), emit: long_genome_size
        tuple val(meta), env('GENOMESIZE'), env('SHORTCOVERAGE'), env('LONGCOVERAGE'), path(r1), path(r2), path(se), path(long_reads), emit: hybrid_genome_size
        path("*.log"), emit: logs
        tuple val(meta), val("genomestats"), path("length_stats.log"), emit: report, optional: true
        tuple val(meta), val("genomestats"), path("long_length_stats.log"), path("short_length_stats.log"), emit: report_hybrid, optional: true

    script:
    if( meta.sample_type == 'short' )
        """
        echo -e "${r1}\n${r2}" > kmc_input.txt
        if [[ \$(zgrep -c '+' ${se}) -gt 0 ]]; then
            echo ${se} >> kmc_input.txt
            seqfu stats --noheader --threads $task.cpus --precision 0 ${r1} ${r2} ${se} > length_stats.log
        else
            seqfu stats --noheader --threads $task.cpus --precision 0 ${r1} ${r2} > length_stats.log
        fi
        NUMBASES=\$(awk '{ sum += \$3 } END { print sum }' length_stats.log)

        mkdir tmp_kmc
        KMERSIZE=21
        MINCOPIES=2
        MAXCOPIES=10000
        MEM=\$(echo $task.memory | awk '{print \$1}')
        kmc -k\$KMERSIZE -ci\$MINCOPIES -cs\$MAXCOPIES -r -m\$MEM -t$task.cpus @kmc_input.txt ${meta.sample_id}.kmc tmp_kmc
        kmc_tools transform ${meta.sample_id}.kmc histogram ${meta.sample_id}.kmc.histo -cx\$MAXCOPIES
        if ! genomescope2 --input ${meta.sample_id}.kmc.histo --kmer_length \$KMERSIZE --ploidy 1 -o ./ > genome_size.log; then
            echo '1:1:1:1:1:1' > genome_size.log
            echo 'Failed to calculate genome size' > summary.txt
        fi

        GENOMESIZE=\$(tail -n1 genome_size.log | cut -d':' -f 6)
        cat summary.txt >> genome_size.log

        COVERAGE=\$((NUMBASES/GENOMESIZE))
        SHORTCOVERAGE=1
        LONGCOVERAGE=1
        """
    else if( meta.sample_type == 'long' )
        """
        seqfu stats --noheader --threads $task.cpus --precision 0 ${long_reads} > length_stats.log
        NUMREADS=\$(cut -f 2 length_stats.log)
        NUMBASES=\$(cut -f 3 length_stats.log)

        # min number of reads for lrge is 5000
        if [[ \$NUMREADS -gt 5000 ]]; then
            GENOMESIZE=\$(lrge -t $task.cpus ${long_reads} 2> genome_size.log)
        else
            mkdir tmp_kmc
            KMERSIZE=21
            MINCOPIES=2
            MAXCOPIES=10000
            MEM=\$(echo $task.memory | awk '{print \$1}')
            kmc -k\$KMERSIZE -ci\$MINCOPIES -cs\$MAXCOPIES -r -m\$MEM -t$task.cpus ${long_reads} ${meta.sample_id}.kmc tmp_kmc
            kmc_tools transform ${meta.sample_id}.kmc histogram ${meta.sample_id}.kmc.histo -cx\$MAXCOPIES
            if ! genomescope2 --input ${meta.sample_id}.kmc.histo --kmer_length \$KMERSIZE --ploidy 1 -o ./ > genome_size.log; then
                echo '1:1:1:1:1:1' > genome_size.log
                echo 'Failed to calculate genome size' > summary.txt
            fi

            GENOMESIZE=\$(tail -n1 genome_size.log | cut -d':' -f 6)
            cat summary.txt >> genome_size.log
        fi

        COVERAGE=\$((NUMBASES/GENOMESIZE))
        SHORTCOVERAGE=1
        LONGCOVERAGE=1
        """
    else if( meta.sample_type == 'hybrid' )
        """
        seqfu stats --noheader --threads $task.cpus --precision 0 ${long_reads} > long_length_stats.log
        LONGNUMREADS=\$(cut -f 2 long_length_stats.log)
        LONGNUMBASES=\$(cut -f 3 long_length_stats.log)

        if [[ \$(zgrep -c '+' ${se}) -gt 0 ]]; then
            echo ${se} > kmc_input.txt
            seqfu stats --noheader --threads $task.cpus --precision 0 ${r1} ${r2} ${se} > short_length_stats.log
        else
            seqfu stats --noheader --threads $task.cpus --precision 0 ${r1} ${r2} > short_length_stats.log
        fi
        SHORTNUMBASES=\$(awk '{ sum += \$3 } END { print sum }' short_length_stats.log)

        # min number of reads for lrge is 5000
        if [[ \$LONGNUMREADS -gt 5000 ]]; then
            GENOMESIZE=\$(lrge -t $task.cpus ${long_reads} 2> genome_size.log)
        else
            echo -e "${r1}\n${r2}\n${long_reads}" >> kmc_input.txt

            mkdir tmp_kmc
            KMERSIZE=21
            MINCOPIES=2
            MAXCOPIES=10000
            MEM=\$(echo $task.memory | awk '{print \$1}')
            kmc -k\$KMERSIZE -ci\$MINCOPIES -cs\$MAXCOPIES -r -m\$MEM -t$task.cpus @kmc_input.txt ${meta.sample_id}.kmc tmp_kmc
            kmc_tools transform ${meta.sample_id}.kmc histogram ${meta.sample_id}.kmc.histo -cx\$MAXCOPIES
            if ! genomescope2 --input ${meta.sample_id}.kmc.histo --kmer_length \$KMERSIZE --ploidy 1 -o ./ > genome_size.log; then
                echo '1:1:1:1:1:1' > genome_size.log
                echo 'Failed to calculate genome size' > summary.txt
            fi

            GENOMESIZE=\$(tail -n1 genome_size.log | cut -d':' -f 6)
            cat summary.txt >> genome_size.log
        fi

        SHORTCOVERAGE=\$((SHORTNUMBASES/GENOMESIZE))
        LONGCOVERAGE=\$((LONGNUMBASES/GENOMESIZE))
        COVERAGE=1
        """
    else
        error "Invalid alignment mode: ${meta.sample_type}"

    stub:
    """
    GENOMESIZE=234813
    COVERAGE=50
    touch length_stats.log
    touch genome_size.log
    """
}
