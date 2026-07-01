#!/bin/bash

# sgb_to_gtdb_profile.py converts metaphlan (CHOCOPhlAn) "SGB" taxonomy
# to GTDB taxonomy. The output is a metaphlan-style report, with no NCBI_tax_id, less # headers,
# Each metaphlan release comes with it's own internal
# SGB2GTDB mapping file installed 
# (eg  https://github.com/biobakery/MetaPhlAn/blob/master/metaphlan/utils/mpa_vOct22_CHOCOPhlAnSGB_202212_SGB2GTDB.tsv)

DATABASE=./databases/metaphlan_db

# sgb_to_gtdb_extra_cols.py must be run from its installed location inside the
# metaphlan package (see install_custom_script.sh), since it loads the
# SGB2GTDB mapping file relative to its own location. Resolve that location
# dynamically from the active Python environment.
SGB_TO_GTDB_SCRIPT=$(python3 -c "import os, metaphlan; print(os.path.join(os.path.dirname(metaphlan.__file__), 'utils', 'sgb_to_gtdb_extra_cols.py'))")

for f in results/*_metaphlan.txt; do
    sample=$(basename $f _metaphlan.txt)

    echo "Converting ${f} to results/${sample}_metaphlan-gtdb.txt"

    #sgb_to_gtdb_profile.py \
    "${SGB_TO_GTDB_SCRIPT}" \
        -d ${DATABASE}/mpa_vOct22_CHOCOPhlAnSGB_202212.pkl \
        -i ${f} \
        -o results/${sample}_metaphlan-gtdb.txt

    # Change the "N/A" values to NA
    sed -i s'/N\/A/NA/g' results/${sample}_metaphlan-gtdb.txt
done
