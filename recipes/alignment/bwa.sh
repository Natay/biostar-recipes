set -ueo pipefail

# Get parameters.
INPUT={{sequence.value}}
GENOME={{genome.value}}
URL={{runtime.job_url}}

# Internal parameters.

# Bwa index.
INDEX_DIR=$(dirname ${GENOME})/bwa
mkdir -p ${INDEX_DIR}
INDEX=${INDEX_DIR}/{{genome.uid}}

# Fasta index.
GENOME_FAIDX=${GENOME}.fai

# Work directory.
WORK={{runtime.work_dir}}/work
mkdir -p ${WORK}

# Main results.
RESULT_VIEW={{runtime.work_dir}}/{{settings.index}}
OUTPUT=${WORK}/aligned.bam

# Build bwa index if not exist.

if [ ! -f "$INDEX.bwt" ]; then
echo "Building bwa index."
bwa index -p ${INDEX} ${GENOME}
fi

# Align sequences

echo  "Mapping reads to the genome."
bwa mem -t 4 ${INDEX} ${INPUT}  | samtools view -b |samtools sort >${OUTPUT}
samtools index ${OUTPUT}

echo "Computing statistics."
echo "--------------------"
samtools flagstat ${OUTPUT}
echo "--------------------"

# Get samtools flagstats results.
samtools flagstat ${OUTPUT} >${WORK}/alignment_stats.txt

# Get number of reads mapped to each chromosome.
samtools idxstats ${OUTPUT} >${WORK}/chrom_mapping.txt

echo "Generating plots."

# Plot results.
python -m biostar.tools.align.plotter ${WORK}/alignment_stats.txt ${WORK}/chrom_mapping.txt >${RESULT_VIEW}

# Build genome index if not exist.
if [ ! -f "$GENOME_FAIDX" ]; then
echo "Building genome index."
samtools faidx ${GENOME}
fi

# Link genome to workdir.
ln -s $GENOME $WORK
ln -s $GENOME_FAIDX $WORK

# Generate igv visualization.
echo "Generating IGV visualization file."
python -m biostar.tools.igv.visualization $URL $WORK >igv.xml

