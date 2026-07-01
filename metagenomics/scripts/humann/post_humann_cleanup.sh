#!/bin/bash

# Post HUMAnN run we keep the metaphlan output and delete the other intermediates

for d in output/*; do 
  mv ${d}/*_humann_temp/*_metaphlan_bugs_list.tsv ${d}
  mv ${d}/*_humann_temp/*.log ${d}
  rm -rf ${d}/*_humann_temp
done

find output -name "*.tsv" -exec gzip {} \;
rm -f tmp/*.gz
