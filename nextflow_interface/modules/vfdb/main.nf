 #!/usr/bin/env nextflow

process VFDB{
     tag "$meta.sample_id"
     publishDir "${params.output}/${meta.sample_id}/vfdb", mode: 'copy'
     conda "${projectDir}/modules/vfdb/environment.yaml"
     memory { workflow.stubRun ? 64.MB : 256.MB * task.attempt }
     cpus { workflow.stubRun ? 1 : (params.threads >= 8 ? 8 : params.threads) }


    input:
        tuple val(meta), path(prot)

    output:
        path("${meta.sample_id}.vf.tsv"), emit: vf_tsv
        path("${meta.sample_id}.json.gz"), emit: json

    script:
    """
    diamond blastp --query ${prot} --db ${params.databaseDir}/vfdb.dmnd --id 80 --query-cover 80 --subject-cover 80 --out ${meta.sample_id}.vf.tsv --outfmt 6 qseqid sseqid qlen slen qstart qend sstart send length pident evalue bitscore --threads ${task.cpus}
    parse_vfdb.py ${meta.sample_id}.vf.tsv ${meta.sample_id}
    """

    stub:
    """
    touch ${meta.sample_id}.vf.tsv
    touch ${meta.sample_id}.json.gz
    """
}
