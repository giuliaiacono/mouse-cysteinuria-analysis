# HUMAnN


## Setup
```bash
# mamba create -n metaphlan -c bioconda metaphlan=4 humann=3.8
conda activate metaphlan

humann_test

humann_databases --download chocophlan full databases/ChocoPhlAn
humann_databases --download uniref uniref90_diamond databases/humann_uniref90_diamond
```

## Run

We will start by running HUMAnN from raw reads (it can also be run starting with filtered assemblies)

```bash
./run_humann.sh
```

Remove tmp files, gzip tsvs:
```bash
./post_humann_cleanup.sh
```

Convert output tables to relative abundance units, regroup counts into different classes (eg GO, Kegg orthology, MetaCyc, EggNOG, etc), merge all samples into one table:
```bash
./postproc_tables.sh
```

Merged tables for downstream analysis are in `output/genefamilies*.relab.tsv.gz` and `pathabundance.relab.tsv.gz`.

Manually added a 'Group' column to the `pathabundance.relab.metadata.tsv` file, and ran `create_plots.py`. Plots and markdown/html in `plots/`.

Create pathway abundance tables without Abx samples, generate plots:
```bash
cd output

awk -F'\t' 'NR==1{for(i=1;i<=NF;i++) if($i !~ /^Abx-/){cols[++n]=i} } {for(i=1;i<=n;i++) printf "%s%s", $(cols[i]), (i==n?"\n":"\t")}' pathabundance.cpm.metadata.tsv >pathabundance.cpm.metadata.het_homo.tsv

awk -F'\t' 'NR==1{for(i=1;i<=NF;i++) if($i !~ /^Abx-/){cols[++n]=i} } {for(i=1;i<=n;i++) printf "%s%s", $(cols[i]), (i==n?"\n":"\t")}' pathabundance.relab.metadata.tsv >pathabundance.relab.metadata.het_homo.tsv

cd ..
./create_plots.py
```
