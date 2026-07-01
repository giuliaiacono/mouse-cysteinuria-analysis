#!/usr/bin/env python
__author__ = 'Aitor Blanco (aitor.blancomiguez@unitn.it), Andrew Perry (Andrew.Perry@monash.edu)'
__version__ = '4.1.1'
__date__ = '23 Aug 2023'

import os
import time
import argparse as ap
try:
    from .util_fun import info, error
    from .database_controller import MetaphlanDatabaseController
except ImportError:
    from util_fun import info, error
    from database_controller import MetaphlanDatabaseController


def read_params() -> ap.Namespace:
    p = ap.ArgumentParser(description="", formatter_class=ap.ArgumentDefaultsHelpFormatter)
    p.add_argument('-i', '--input', type=str, default=None, help="The input profile")
    p.add_argument('-d', '--database', type=str, default='latest', help="The path to the MetaPhlAn PKL database")
    p.add_argument('-o', '--output', type=str, default=None, help="The output profile")
    return p.parse_args()


def check_params(args: ap.Namespace):
    if not args.input:
        error('-i (or --input) must be specified', exit=True)
    if not args.output:
        error('-o (or --output) must be specified', exit=True)


def get_gtdb_profile(mpa_profile: str, gtdb_profile: str, database: str):
    tax_levels = ['d', 'p', 'c', 'o', 'f', 'g', 's']
    sgb2gtdb = dict()
    with open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "{}_SGB2GTDB.tsv".format(database)), 'r') as read_file:
        for line in read_file:
            line = line.strip().split('\t')
            sgb2gtdb[line[0]] = line[1]

    header_columns = ['#clade_name', 'clade_taxid', 'relative_abundance', 'coverage', 'estimated_number_of_reads_from_the_clade']
    with open(gtdb_profile, 'w') as wf:
        with open(mpa_profile, 'r') as rf:
            unclassified = 0
            abundances = {x: dict() for x in tax_levels}
            for line in rf:
                if line.startswith('#mpa_'):
                    wf.write(line)
                    wf.write('\t'.join(header_columns) + '\n')
                elif line.startswith('UNCLASSIFIED'):
                    unclassified = float(line.strip().split('\t')[2])
                    wf.write(f'UNCLASSIFIED\tNA\t{unclassified}\tNA\tNA\n')
                elif 't__SGB' in line:
                    line_parts = line.strip().split('\t')
                    gtdb_tax = sgb2gtdb[line_parts[0].split('|')[-1][3:]]
                    additional_info = '\t'.join(line_parts[1:]) if len(line_parts) > 2 else '\tNA' * (len(header_columns) - 2)
                    wf.write(f"{gtdb_tax}\t{additional_info}\n")

                    if gtdb_tax not in abundances['s']:
                        abundances['s'][gtdb_tax] = 0
                    abundances['s'][gtdb_tax] += float(line_parts[2])

def main():
    t0 = time.time()
    args = read_params()
    info("Start execution")
    check_params(args)
    database_controller = MetaphlanDatabaseController(args.database)
    get_gtdb_profile(args.input, args.output, database_controller.get_database_name())
    exec_time = time.time() - t0
    info("Finish execution ({} seconds)".format(round(exec_time, 2)))


if __name__ == "__main__":
    main()
