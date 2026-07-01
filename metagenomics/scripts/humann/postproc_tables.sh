#!/bin/bash
set -e
set -o pipefail
set -o xtrace

SAMPLES="Abx-1_S1 Abx-2_S2 Abx-3_S3 Abx-4_S4 Abx-5_S5 Het-1_S6 Het-2_S7 Het-3_S8 Het-4_S9 Het-5_S10 Homo-1_S11 Homo-2_S12 Homo-3_S13 Homo-4_S14 Homo-5_S15"

find output -name "*.gz" -exec gunzip {} \;

for sample in $SAMPLES; do
    prefix="output/${sample}/${sample}"

    humann_renorm_table --input "${prefix}_genefamilies.tsv" --output "${prefix}_genefamilies.relab.tsv" --units relab
    humann_renorm_table --input "${prefix}_pathabundance.tsv" --output "${prefix}_pathabundance.relab.tsv" --units relab
    
    # cpm = (copies per million) = relative abundance * 1 million
    humann_renorm_table --input "${prefix}_genefamilies.tsv" --output "${prefix}_genefamilies.cpm.tsv" --units cpm
    humann_renorm_table --input "${prefix}_pathabundance.tsv" --output "${prefix}_pathabundance.cpm.tsv" --units cpm

    mkdir -p "output/${sample}/regrouped"
    rg_prefix="output/${sample}/regrouped/${sample}"
    
    for group in uniref90_rxn uniref90_go uniref90_ko uniref90_level4ec uniref90_pfam uniref90_eggnog; do
        humann_regroup_table --input "${prefix}_genefamilies.tsv" --groups "${group}" --output "${rg_prefix}_genefamilies_${group}.tsv"
        humann_renorm_table --input "${rg_prefix}_genefamilies_${group}.tsv" --output "${rg_prefix}_genefamilies_${group}.relab.tsv" --units relab
    done
done

# Create directories with symlinks so we have every sample in one directory, for humann_join_tables
mkdir -p output/all
mkdir -p output/all/regrouped

for sample in $SAMPLES; do
    ln -s "../${sample}/${sample}_genefamilies.relab.tsv" "output/all/${sample}_genefamilies.relab.tsv"
    ln -s "../${sample}/${sample}_pathabundance.relab.tsv" "output/all/${sample}_pathabundance.relab.tsv"
    ln -s "../${sample}/${sample}_genefamilies.cpm.tsv" "output/all/${sample}_genefamilies.cpm.tsv"
    ln -s "../${sample}/${sample}_pathabundance.cpm.tsv" "output/all/${sample}_pathabundance.cpm.tsv"

    for group in uniref90_rxn uniref90_go uniref90_ko uniref90_level4ec uniref90_pfam uniref90_eggnog; do
        ln -s "../../${sample}/regrouped/${sample}_genefamilies_${group}.relab.tsv" "output/all/regrouped/${sample}_genefamilies_${group}.relab.tsv"
    done
done

# Make merged tables with a column for every sample
humann_join_tables --input output/all --file_name "_genefamilies.relab" --output output/genefamilies.relab.tsv
humann_join_tables --input output/all --file_name "_pathabundance.relab"  --output output/pathabundance.relab.tsv
humann_join_tables --input output/all --file_name "_genefamilies.cpm" --output output/genefamilies.cpm.tsv
humann_join_tables --input output/all --file_name "_pathabundance.cpm"  --output output/pathabundance.cpm.tsv


for group in uniref90_rxn uniref90_go uniref90_ko uniref90_level4ec uniref90_pfam uniref90_eggnog; do
    humann_join_tables --input output/all/regrouped \
                    --file_name "_genefamilies_${group}.relab" \
                    --output output/genefamilies_${group}.relab.tsv
done

find output -name "*.tsv" -exec gzip {} \;