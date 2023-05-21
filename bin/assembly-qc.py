#!/usr/bin/env python3

import argparse
import logging
import os
import re
import sys

from pathlib import Path

from Bio import SeqIO


RE_COVERAGE = re.compile(r'cov_(\d+(?:\.\d+))')  # detection of SPAdes seq coverage
RE_CIRC = re.compile(r'circular=true', re.IGNORECASE)  # detection of Unicycler circularized sequences

parser = argparse.ArgumentParser(
    prog='assembly-prettify',
    description='Prettify assembly sequences.',
    add_help=False
)
arg_group_io = parser.add_argument_group('Input / Output')
arg_group_io.add_argument('genome', metavar='<genome>', help='Genome sequence in fasta format')
arg_group_io.add_argument('--min-contig-length', '-m', action='store', type=int, default=1, dest='min_contig_length', help='Minimum contig size (default = 1; 200 in compliant mode)')
arg_group_io.add_argument('--prefix', '-p', action='store', default=None, help='Prefix for output files')
arg_group_io.add_argument('--output', action='store', default=os.getcwd(), help='Output directory (default = current working directory)')
arg_group_general = parser.add_argument_group('General')
arg_group_general.add_argument('--help', '-h', action='help', help='Show this help message and exit')
arg_group_general.add_argument('--verbose', '-v', action='store_true', help='Print verbose information')
args = parser.parse_args()

log = logging.getLogger('MAIN')

try:
    if(args.genome == ''):
        raise ValueError('File path argument must be non-empty')
    genome_in_path = Path(args.genome).resolve()
except:
    log.error('provided genome file not valid! path=%s', args.genome)
    sys.exit(f'ERROR: genome file ({args.genome}) not valid!')

contigs = []
with genome_in_path.open() as fh_in:
    for record in SeqIO.parse(fh_in, 'fasta'):
        seq = str(record.seq).upper()
        contig = {
            'id': record.id,
            'description': record.description,
            'sequence': seq,
            'length': len(seq),
            'complete': False,
            'depth': None
        }
        if RE_CIRC.search(contig['description']) is not None:
            contig['complete'] = True
        m = RE_COVERAGE.search(contig['description'])
        if m is not None:
            contig['depth'] = float(m.group(1))
        log.info(
            'in: id=%s, length=%i, complete=%s, depth=%s, description=%s',
            contig['id'], contig['length'], contig['complete'], contig['depth'], contig['description']
        )
        if contig['length'] >= args.min_contig_length:
            contigs.append(contig)

prefix = args.prefix if args.prefix else 'assembly'
genome_out_path = Path(args.output).joinpath(f'{prefix}.fna').resolve()
with genome_out_path.open('w') as fh_out:
    contig_no = 1
    for contig in sorted(contigs, key=lambda k: k['length'], reverse=True):
        contig_id = f'contig_{contig_no:04}'
        # depth = f"depth={contig['depth']:.2f}" if contig['depth'] is not None else ''
        fh_out.write(f">{contig_id} length={contig['length']} complete={contig['complete']}\n")
        seq = contig['sequence']
        for i in range(0, len(seq), 70):
            fh_out.write(seq[i:i + 70])
            fh_out.write('\n')
        contig_no += 1

