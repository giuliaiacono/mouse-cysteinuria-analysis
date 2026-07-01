# HPC data processing scripts

These are the scripts originally run on the HPC cluster to go from raw paired-end
reads to the merged tables consumed by the `workflowr/` R analysis
(`workflowr/analysis/metaphlan.Rmd`, `workflowr/analysis/humann.Rmd`). The
downstream statistical steps (ANCOM-BC2 differential species abundance, MaAsLin2
differential pathway abundance) are implemented directly in those R Markdown
files, not as standalone scripts.

## Pipeline order

1. **Host/PhiX depletion** — `run-preproc-only.sh`
   Runs the [nf-core/mag](https://nf-co.re/mag/2.3.2/) pipeline (Nextflow) with
   assembly/binning stages skipped, to perform read QC/trimming and Bowtie2-based
   removal of host (*Mus musculus*, GRCm38 Ensembl release 102) and PhiX reads.
   Produces the `*.host_removed.unmapped_{1,2}.fastq.gz` files consumed by both
   steps below.

2. **`metaphlan/`** — MetaPhlAn4 taxonomic profiling
   - `sbatch_metaphlan.sh` / `run_all_metaphlan.sh` — run MetaPhlAn4 per sample
     (SLURM array via sbatch) against the ChocoPhlAn (vOct22) database.
   - `convert_to_gtdb.sh` / `sgb_to_gtdb_extra_cols.py` / `install_custom_script.sh`
     — convert MetaPhlAn's native SGB taxonomy to GTDB taxonomy.
   - `merge.sh` / `merge_metaphlan.py` — merge per-sample profiles into
     `merged-gtdb.tsv` (this is `pipeline/metaphlan/results-gtdb-nounclassified/merged-gtdb.tsv`
     in this bundle).
   - `conda_environment.yml` — pinned conda environment (MetaPhlAn 4.0.6,
     Bowtie2 2.5.1, etc).
   - `NOTES.md` — original run notes/commands.

3. **`humann/`** — HUMAnN functional/pathway profiling
   - `run_humann.sh` — runs HUMAnN (v3.8) per sample against UniRef90
     (`uniref90_201901b_full`)/MetaCyc, using the host-depleted reads.
   - `post_humann_cleanup.sh` — tidy up per-sample intermediate files.
   - `postproc_tables.sh` — normalise counts to relative abundance / CPM,
     regroup gene families (eggNOG, GO, KO, level4EC, Pfam, MetaCyc reactions),
     and join per-sample tables into the merged tables consumed by the report
     (`pipeline/humann/output/{genefamilies,pathabundance}.cpm.tsv` etc, in this
     bundle).
   - `NOTES.md` — original run notes/commands.

Database paths, Slurm account/partition names, and filesystem paths reflect the
original HPC environment and will need adjusting to run elsewhere.
