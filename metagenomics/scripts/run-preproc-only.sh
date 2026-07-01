#!/bin/bash
set -e
set -o pipefail

export SINGULARITY_CACHEDIR=$(pwd)/singularity_cache
export TMDIR=$(pwd)/tmp
export NXF_TEMP=${TMPDIR}
export NXF_SINGULARITY_CACHEDIR="${SINGULARITY_CACHEDIR}"
export NXF_OPTS='-Xms1g -Xmx7g'
export NXF_ANSI_LOG='false'
export NXF_VER=22.10.4

export SKIP_FLAGS=" --skip_spades --skip_spadeshybrid --skip_megahit --skip_quast --skip_binning --skip_prodigal "
#export SKIP_FLAGS=" "

# Set this to the path of a local reference genome,
# Mus musculus GRCm38 Ensembl release-102
export LAXY_IGENOMES="${LAXY_IGENOMES:-$(pwd)/references/iGenomes}"
export DATABASES="$(pwd)/databases"
# Test run
# nextflow run nf-core/mag -r 2.3.2 -profile test,singularity \
#   --outdir results-test

nextflow run nf-core/mag -r 2.3.2 -profile singularity \
  --input $(pwd)'/fastqs/*{R1,R2}_001.fastq.gz' \
  --outdir results-preproc \
  --save_clipped_reads \
  --save_phixremoved_reads \
  --save_hostremoved_reads \
  --host_fasta ${LAXY_IGENOMES}/Mus_musculus/Ensembl/GRCm38.release-102/Sequence/WholeGenomeFasta/genome.fa \
  ${SKIP_FLAGS} \
  -with-tower \
  -resume
