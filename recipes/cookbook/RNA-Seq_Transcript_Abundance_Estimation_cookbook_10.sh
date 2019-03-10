set -ueo pipefail

# Input reads.
INPUT={{reads.toc}}

# Reference Transcriptome.
TRANSCRIPTS={{transcripts.value}}

# Library type.
LIBRARY={{library.value}}

# Fraction to sub-sample the data.
FRACTION={{fraction.value}}

# Run log to redirect unwanted output.
RUNLOG=runlog/runlog.txt

# This directory should already exist.
mkdir -p runlog

# Directory with Kallisto results.
mkdir -p results

# Directory with intermediate files.
mkdir -p tmp

# Sub-sample data.
if [ ${FRACTION} != 1 ]; then
    READS=reads
    mkdir -p $READS

    # Subsample data.
    echo "Randomly sampling $FRACTION fraction of data"
    cat ${INPUT} | egrep "fastq|fq" | sort |  parallel "seqtk sample -s 11 {} $FRACTION >$READS/{/.}.fq"

    # The name of the new table of contents.
    INPUT=$READS/toc.txt

    # Create table of contents with sub-sampled data.
    ls -1 $READS/*.fq > $INPUT
fi

# Kallisto index directory.
INDEX_DIR={{runtime.local_root}}/indices
mkdir -p ${INDEX_DIR}

# Kallisto index.
INDEX=${INDEX_DIR}/{{transcripts.uid}}.idx

# Build the Kallisto index if it does not already exist.
if [ ! -f ${INDEX} ]; then
    echo "Building the kallisto index."
    kallisto index -i ${INDEX} ${TRANSCRIPTS} >> $RUNLOG 2>&1
else
    echo "Found an existing kallisto index."
fi

# Calculate abundances using kallisto.
if [ ${LIBRARY} == "PE" ]; then
    echo "Running kallisto quant algorithm in paired end mode."
    cat ${INPUT}| egrep "fastq|fq" | sort | parallel -N 2  -j 4 kallisto quant -o results/{1/.}.out  -i ${INDEX} {1} {2} >> $RUNLOG 2>&1
else
    # Obtain the additional parameters for single end mode.

    # Estimated average fragment length.
    FRAG_LEN={{fragment_length.value}}

    # Estimated standard deviation of fragment length.
    FRAG_SD={{fragment_sd.value}}

    # Run kallisto in single end more.
    echo "Running kallisto quant algorithm in single end mode."
    cat ${INPUT}| egrep "fastq|fq" | sort | parallel -j 4 kallisto quant -o results/{1/.}.out  -i ${INDEX} --single -l ${FRAG_LEN} -s ${FRAG_SD} {} >> $RUNLOG 2>&1
fi

# Create a combined count table for all samples.

# Directory name is the sample name.
# Rename est_count column to sample name and extract it into a new file.
ls -d results/* | cut -f 2 -d "/" | parallel "sed -e 1s/est_counts/{.}/ results/{}/abundance.tsv | cut -f 4 >tmp/{}_counts.txt"

# Combine all counts into a single file.
paste tmp/*counts.txt > tmp/all.txt

# Add  transcript ids to the counts.
ls -d results/* | head -1 | parallel cat {}/abundance.tsv | cut -f 1 | paste - tmp/all.txt > combined_abundance.txt
