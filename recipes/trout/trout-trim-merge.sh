set -ueo pipefail

# Input parameters.

INPUT={{reads.toc}}
SAMPLESHEET={{samplesheet.value}}
QUALITY={{quality.value}}
MIN_LEN={{min_length.value}}
MAX_LEN={{max_length.value}}

# Run log to redirect unwanted output.
mkdir -p runlog
RUNLOG=runlog/runlog.txt

# Directory that holds trimmed reads.
TDIR=trimmed

# Directory that holds merged reads.
MDIR=merged

# Directory with reads that are filtered for Ns.
FDIR=filtered

# Directory with size selected reads.
SDIR=selected

# Get data path.
DATA_DIR=$(dirname $(cat $INPUT| head -1 ))

# Trim by quality and then trim forward and reverse primers.
echo "Trimming by quality and removing primers."
mkdir -p $TDIR
cat ${SAMPLESHEET} | parallel --header : --colsep , -j 4 cutadapt --quiet -q $QUALITY -g ^{barcode}{fwd_primer} \
-G ^{barcode}{rev_primer} --pair-filter both --discard-untrimmed ${DATA_DIR}/{read1} ${DATA_DIR}/{read2} -o $TDIR/{read1} -p $TDIR/{read2}

# Merge trimmed reads.
echo "Merging  paired end reads."
mkdir -p $MDIR
cat ${SAMPLESHEET} | parallel --header : --colsep , -j 2 bbmerge.sh  ultrastrict=t in1=$TDIR/{read1} in2=$TDIR/{read2} out=$MDIR/{sample}.fastq.gz 2>>$RUNLOG

# Remove reads with Ns.
echo "Filtering reads with Ns."
mkdir -p $FDIR
cat ${SAMPLESHEET} | parallel --header : --colsep , -j 2  bbduk.sh in=$MDIR/{sample}.fastq.gz out=$FDIR/{sample}.fastq.gz maxns=0 2>>$RUNLOG

# Extract reads in a size range.
echo "Selecting  reads based on size range."
mkdir -p $SDIR
cat ${SAMPLESHEET} | parallel --header : --colsep , -j 2 reformat.sh in=$FDIR/{sample}.fastq.gz out=$SDIR/{sample}.fastq.gz minlength=$MIN_LEN maxlength=$MAX_LEN 2>>$RUNLOG

#
# --------------------------
# Generate a stats table.
# ---------------------------
#
echo "Generating a stats table."

# File with basic stats.
TABLE=stats.txt

echo -e "Sample\tTotal(read1)\tTrimmed\tMerged\tFiltered\tsize-selected" >$TABLE

sed 1d $SAMPLESHEET | while IFS='\t' read -r line
do
        sample=$(echo $line| cut -d "," -f 1)
        R1=$(echo $line| cut -d "," -f 7)
        total=$(bioawk -c fastx '{print $name}' $DATA_DIR/$R1 |wc -l)
        trimmed=$(bioawk -c fastx '{print $name}' $TDIR/$R1 |wc -l)
        merged=$(bioawk -c fastx '{print $name}' $MDIR/${sample}.fastq.gz |wc -l)
        filtered=$(bioawk -c fastx '{print $name}' $FDIR/${sample}.fastq.gz |wc -l)
        selected=$(bioawk -c fastx '{print $name}' $SDIR/${sample}.fastq.gz | wc -l)
        echo -e "$sample\t$total\t$trimmed\t$merged\t$filtered\t$selected" >>$TABLE
done

