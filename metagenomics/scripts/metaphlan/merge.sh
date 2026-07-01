#!/bin/bash
set -o xtrace

merge_metaphlan_tables.py --overwrite results/*_metaphlan.txt >results/merged_abundance_table.txt

# When using our custom converted GTDB profiles that include all the columns, 
# we don't need the --gtdb_profiles flag
#merge_metaphlan_tables.py --gtdb_profiles results/*_metaphlan-gtdb.txt >results/merged_abundance_table-gtdb.txt

# merge_metaphlan_tables.py --overwrite results/*_metaphlan-gtdb.txt >results/merged_abundance_table-gtdb.txt

./merge_metaphlan.py results/ >results/merged-gtdb.tsv
