This repository contains code used for preprocessing and data analysis of untargeted metabolomics of urine and serum, and metagenomics of stool of homozygote, heterozygote Slc7a9 G105R knock-in mice and wiltype controls.

Publication title: "Generation of a novel Slc7a9G105R mutant mouse identifies new biomarkers for cystinuria".

# Untargeted metabolomics analysis of serum and urine

Untargeted metabolomics preprocessing and analyses reported in the associated manuscript: import MSDIAL output into R; preprocess and annotate features using pmp and the HMDB database; perform differential abundance and pathway analysis using Limma; perform correlation analyses using Hmisc.

- **Authors:** Giulia Iacono (analysis); Nirmal Bhatt, Malcolm Starkey (study)

## Preprocessed data

Raw output from MSDIAL is included in the `01_msdial/` folder, while pmp preprocessed outputs including normalised and filtered metabolite intensity tables and tables with features annotations and information are included in the `02_preprocessing/` folder.

# Shotgun metagenomics WGS of stool

Reproducible [workflowr](https://github.com/workflowr/workflowr) analysis of the faecal microbiome of cystinuria-model mice (Abx / Het / Homo groups), short-read shotgun WGS. This bundle covers the fecal metagenomics analyses reported in the associated manuscript: MetaPhlAn4 taxonomic profiling, ANCOM-BC2 differential species abundance, and HUMAnN functional/pathway profiling with MaAsLin2 differential pathway abundance.

- **Authors:** Andrew Perry (analysis); Nirmal Bhatt, Malcolm Starkey (study)

## Raw data and preprocessed data

Raw shotgun metagenomic sequencing reads are deposited at NCBI SRA under BioProject [PRJNA1131664](https://www.ncbi.nlm.nih.gov/bioproject/PRJNA1131664).
This bundle contains only downstream-processed data (host-depleted read profiles and merged abundance tables) and analysis code; it does not include raw reads. 
Scripts in `scripts/` were used to produce the downstream processed data from the raw reads.

## Layout

```
.
├── workflowr/        # workflowr R project (source + rendered report)
│   ├── analysis/     # report R Markdown + helper R scripts
│   ├── data/         # metadata + cached ANCOM-BC2 results (*.rds)
│   ├── docs/         # pre-rendered HTML report (open docs/index.html)
│   ├── renv.lock     # pinned R package environment
│   └── _workflowr.yml
├── pipeline/         # minimal upstream pipeline outputs consumed by the report
│   ├── metaphlan/...                   # MetaPhlAn4 merged table
│   └── humann/output/                  # HUMAnN gene-family / pathway (CPM) tables
└── scripts/          # HPC scripts used to produce pipeline/ from raw reads
    ├── run-preproc-only.sh             # Bowtie2 host/PhiX depletion (nf-core/mag)
    ├── metaphlan/                      # MetaPhlAn4 run + GTDB conversion + merge
    └── humann/                         # HUMAnN run + table post-processing
```

`pipeline/` is mirrored at the bundle root because the analysis code reads it via relative paths (`../pipeline/...`) from `workflowr/`. 
Only the inputs the report actually consumes are included. `scripts/` documents how those pipeline outputs were originally generated on HPC (see `scripts/README.md`); the downstream ANCOM-BC2 and MaAsLin2 statistical steps are implemented directly in the `workflowr/analysis/*.Rmd` files rather than as separate scripts.

## Viewing the report

Open `workflowr/docs/index.html` in a browser.

## Rebuilding from source

```r
# from within workflowr/
renv::restore()          # restore pinned packages from renv.lock
workflowr::wflow_build() # re-render analysis/*.Rmd -> docs/
```

The slow ANCOM-BC2 differential-abundance steps are cached as `workflowr/data/ancombc2*.rds` and are reused on rebuild rather than recomputed.
