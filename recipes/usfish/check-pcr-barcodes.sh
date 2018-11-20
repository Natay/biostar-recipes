set -ue

# The input directory for the data
DDIR=$(dirname {{reads.value}})

# The list of files in the directory.
SHEET={{sheet.value}}

# Library type of input reads.
LIBRARY={{library.value}}

# Acceptable error rate.
ERROR={{error_rate.value}}

# Output generated while running the tool.
RUNLOG=runlog/runlog.txt

# Wipe clean the runlog.
echo "" > $RUNLOG

# How many parallel processes to allow.
N=2

# Create main store for results
STORE=results
mkdir -p $STORE

# Directory to store reads with correct PCR barcode.
CORRECT=$STORE/true-barcodes
mkdir -p $CORRECT

# Directory to store reads with incorrect PCR barcode.
INCORRECT=$STORE/false-barcodes
mkdir -p $INCORRECT

{% if library.value == "SE" %}
    # Filter out reads with in correct PCR barcode.
    cat ${SHEET} | parallel --header : --colsep , -j 2 cutadapt -g ^{fwd_barcode} -e $ERROR --no-trim $DDIR/{read1} -o $CORRECT/{read1} --untrimmed-output $INCORRECT/false_barcode_{read1} >>$RUNLOG

{% else %}
    # Filter out reads with in correct PCR barcode.
    cat ${SHEET} | parallel --header : --colsep , -j 2 cutadapt -g ^{fwd_barcode} -G ^{rev_barcode} \
    -e $ERROR --pair-filter any --no-trim $DDIR/{read1}  $DDIR/{read2}  -o $CORRECT/{read1} -p $CORRECT/{read2} --untrimmed-output $INCORRECT/false_barcode_{read1} --untrimmed-paired-output $INCORRECT/false_barcode_{read2} >>$RUNLOG

{% endif %}

# Read stats after PCR barcode check.
echo "--- Reads with correct PCR-barcode --- "
seqkit stat $CORRECT/*
seqkit stat $CORRECT/* >$STORE/true-barcode-stats.txt

echo -e "\n--- Reads without correct PCR-barcode --- "
seqkit stat $INCORRECT/*
seqkit stat $INCORRECT/* >$STORE/false-barcode-stats.txt
