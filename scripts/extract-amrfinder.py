#!/usr/bin/env python3

import argparse
import logging
import sys

from pathlib import Path


parser = argparse.ArgumentParser(
    prog='extract-amrfinder',
    description='Extract AMR genes detected by AMRFinder.',
    add_help=False
)
arg_group_io = parser.add_argument_group('Input / Output')
arg_group_io.add_argument('results', metavar='<results>', help='Path to result directory')
arg_group_general = parser.add_argument_group('General')
arg_group_general.add_argument('--help', '-h', action='help', help='Show this help message and exit')
arg_group_general.add_argument('--verbose', '-v', action='store_true', help='Print verbose information')
args = parser.parse_args()

log = logging.getLogger('MAIN')

try:
    if(args.results == ''):
        raise ValueError('Results path argument must be non-empty')
    results_path = Path(args.results).resolve()
except:
    log.error('provided results path not valid! path=%s', args.genome)
    sys.exit(f'ERROR: results path ({args.results}) not valid!')

amr_genes = set()
amr_genes_per_sample = {}
for genome_amrfinder_path in results_path.glob('**/*.amrfinder.tsv'):
    with genome_amrfinder_path.open('rt') as fh_in:
        lines = [line.rstrip() for line in fh_in]
    genes = []
    sample = None
    for line in lines[1:]:
        cols = line.split('\t')
        sample = cols[0]
        gene = cols[2]  # gen symbol
        amr_genes.add(gene)
        genes.append(gene)
    if sample is not None:
        amr_genes_per_sample[sample] = genes

amr_genes = sorted(list(amr_genes))
header_genes = '\t'.join(amr_genes)
print(f'Sample\t{header_genes}')
for sample, genes in amr_genes_per_sample.items():
    genes_pa = '\t'.join(['1' if gene in genes else '0' for gene in amr_genes])
    print(f'{sample}\t{genes_pa}')
