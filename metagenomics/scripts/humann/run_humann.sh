#!/bin/bash
set -e
set -o pipefail

mkdir -p tmp output slurm_logs

SAMPLES="Abx-1_S1 Abx-2_S2 Abx-3_S3 Abx-4_S4 Abx-5_S5 Het-1_S6 Het-2_S7 Het-3_S8 Het-4_S9 Het-5_S10 Homo-1_S11 Homo-2_S12 Homo-3_S13 Homo-4_S14 Homo-5_S15"
 
# SAMPLES="Abx-3_S3 Het-1_S6 Het-2_S7 Het-4_S9 Het-5_S10 Homo-1_S11 Homo-2_S12 Homo-4_S14 Homo-5_S15"

# Some samples succeed with --mem=32G, other need more
export TMPDIR=$(pwd)/tmp
for sample in ${SAMPLES}; do
    SBATCH="sbatch --mem=64G --time=7-0:00:00 --cpus-per-task=8 --partition=comp --job-name=humann_${sample} -o slurm_logs/${sample}__%j.out --wrap="
    # humann likes R1 and R2 concatenated, so we do that as a tmp file
    if [[ ! -f tmp/${sample}.fastq.gz ]]; then
      # cat fastqs/trimmed/${sample}_L001_1.fastp.fastq.gz fastqs/trimmed/${sample}_L001_2.fastp.fastq.gz >tmp/${sample}.fastq.gz
      cat fastqs/remove_host/${sample}_L001.host_removed.unmapped_1.fastq.gz fastqs/remove_host/${sample}_L001.host_removed.unmapped_2.fastq.gz >tmp/${sample}.fastq.gz
    fi
   
    if [[ ! -f "output/${sample}/${sample}_pathabundance.tsv" ]]; then 
      ${SBATCH}"\
      humann --input tmp/${sample}.fastq.gz \
             --output output/${sample} \
             --threads 8 \
             --search-mode uniref90 \
             --metaphlan-options \"-t rel_ab --bowtie2db databases/metaphlan/vOct22/metaphlan_db\" \
             --resume \
      "
    fi
done
