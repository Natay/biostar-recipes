set -ue

# The data names get sorted lexicographically.
# Hence an explicit listing of data is required.
# This will be achieved via a sample file.

# We only need the directory where the data resides.
DDIR=$(dirname {{reads.value}})

GENOME={{genome.value}}

CUTOFF={{cutoff.value}}

SHEET={{sheet.value}}

MINLEN={{minlen.value}}

# This directory will hold all intermediary results.
rm -rf results

# This directory holds all intermediary results.
mkdir -p results

# This is the location of the bwa index.
mkdir -p results/index
INDEX=results/index/genome

# Number of simultaneous processes.
PROC=4

# Run log to redirect unwanted output.
RUNLOG=runlog/runlog.txt

# Wipe the runlog in case the job is rerun.
echo "" >$RUNLOG

# Build the bwa index."
bwa index -p ${INDEX} ${GENOME} >> $RUNLOG 2>&1

# Generates the six column tab delimited file that contains
# file1 file2 primer1 primer2 output1 output2 output3

# This directory should already exist.
mkdir -p runlog

# Error correct the sequences.
CDIR=results/corrected
mkdir -p $CDIR
cat ${SHEET} | parallel --header : --colsep , -j $PROC tadpole.sh in1=$DDIR/{read1} in2=$DDIR/{read2} out1=$CDIR/{read1} out2=$CDIR/{read2}  mode=correct k=50 overwrite=t 2>>$RUNLOG

# Use cutadapt to filter out those read that DO NOT contain the primers
FDIR=results/filtered
mkdir -p $FDIR
cat ${SHEET} | parallel --header : --colsep , -j $PROC cutadapt --quiet -g ^{barcode}{fwd_primer} -G ^{barcode}{rev_primer} --pair-filter both --no-trim --discard-untrimmed $CDIR/{read1} $CDIR/{read2} -o $FDIR/{read1} -p $FDIR/{read2}

echo "" > $RUNLOG

# Merge corrected, filtered reads. The 7th column is the sample name plus extension.
MDIR=results/merged
mkdir -p $MDIR
cat ${SHEET} | parallel --header : --colsep , -j $PROC bbmerge.sh ultrastrict=t minoverlap=$MINLEN in1=$FDIR/{read1} in2=$FDIR/{read2} out=$MDIR/{sample}.fq 2>>$RUNLOG

# Read stats after merging
echo "--- Corrected --- "
seqkit stat $CDIR/*
echo "--- Filtered --- "
seqkit stat $FDIR/*
echo "--- Merged --"
seqkit stat $MDIR/*

# The alignments will be stored here.
BDIR=results/bam
mkdir -p $BDIR

# Generate the alignments for each data
# These steps are optional and needed only when investigating/debugging.

#cat ${SHEET} | parallel --header : --colsep , -j $PROC "bwa mem ${INDEX} $DDIR/{read1} $DDIR/{read2} 2>> $RUNLOG | samtools sort > $BDIR/original-{sample}.bam"
#cat ${SHEET} | parallel --header : --colsep , -j $PROC "bwa mem ${INDEX} $CDIR/{read1} $CDIR/{read2} 2>> $RUNLOG | samtools sort > $BDIR/corrected-{sample}.bam"
#cat ${SHEET} | parallel --header : --colsep , -j $PROC "bwa mem ${INDEX} $FDIR/{read1} $FDIR/{read2} 2>> $RUNLOG | samtools sort > $BDIR/filtered-{sample}.bam"
rm -rf $CDIR $FDIR

# Generate the merged alignment that will be used.
cat ${SHEET} | parallel --header : --colsep , -j $PROC "bwa mem ${INDEX} $MDIR/{sample}.fq 2>> $RUNLOG | samtools view -h -q 1 -F 2304 | python -m recipes.code.bamfilter --minlen $MINLEN | samtools sort > $BDIR/{sample}.bam"

# Generate the indices for all BAM files.
ls -1 $BDIR/*.bam | parallel samtools index {}

# Create a results directory
mkdir -p results/counts

# Generate alignment statistics.
cat ${SHEET} | parallel --header : --colsep , -j $PROC "samtools flagstat $BDIR/{sample}.bam > results/counts/{sample}.flagstat.txt"
cat ${SHEET} | parallel --header : --colsep , -j $PROC "samtools idxstats $BDIR/{sample}.bam > results/counts/{sample}.idxstats.txt"

# Create a combined report of all index stats.
echo "Final results in the 'mapped.txt' and 'mapped_percents.txt' files"
python -m recipes.code.combine_samtools_idxstats --cutoff $CUTOFF results/counts/*idxstats*t | column -t -s , > mapped.txt

python -m recipes.code.combine_samtools_idxstats --cutoff $CUTOFF results/counts/*idxstats*t --by_percent | column -t -s , > mapped_percents.txt
