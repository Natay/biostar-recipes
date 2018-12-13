set -ue

# The input directory for the data
DDIR=$(dirname {{reads.value}})

# The reference directory to classify against.
REFERENCE={{reference.value}}

# The sum of each row needs to be above this value.
CUTOFF={{cutoff.value}}

# The minimal hit length for classification.
HITLEN={{hitlen.value}}

# The list of files in the directory.
SHEET={{sheet.value}}

# Library type of input reads.
LIBRARY={{library.value}}

# Output generated while running the tool.
RUNLOG=runlog/runlog.txt

# Wipe clean the runlog.
echo "" > $RUNLOG

# How many parallel processes to allow.
N=2
# Use the taxonomy specific files to build the custom database.
TAXDIR=/export/refs/taxonomy

# Download taxonomy specific files. Run these in  $TAXDIR.
# This operation only needs to be done once for the entire website.
#
# (cd $TAXDIR && wget ftp://ftp.ncbi.nlm.nih.gov/pub/taxonomy/taxdump.tar.gz)
# (cd $TAXDIR && wget ftp://ftp.ncbi.nih.gov/pub/taxonomy/accession2taxid/nucl_gb.accession2taxid.gz)
# (cd $TAXDIR && gunzip taxdump.tar.gz)
# (cd $TAXDIR && gunzip nucl_gb.accession2taxid.gz)
# Create the conversion table (accession to taxid mapping).
# cat $TAXDIR/nucl_gb.accession2taxid | cut -f 1,3 > $TAXDIR/table.txt
# Untar file
# tar -xvf $TAXDIR/taxdump.tar

TABLE=$TAXDIR/table.txt
NODES=$TAXDIR/nodes.dmp
NAMES=$TAXDIR/names.dmp

# Create the custom database.
CUSTOMDB=index
mkdir -p $CUSTOMDB

# Create main store for results
STORE=results
mkdir -p $STORE

# The name of the centrifuge index.
INDEX=$CUSTOMDB/database

# Directory to store classified results
CLASSDIR=$STORE/classified
mkdir -p $CLASSDIR

# Directory to store unclassified reads
UNCLASS=$STORE/unclassified
mkdir -p $UNCLASS

# Directory to store results from centrifuge
COUNTSDIR=$STORE/data
mkdir -p $COUNTSDIR

# Store rarefaction plots and results
RAREFACTION=$STORE/rarefaction
mkdir -p $RAREFACTION

# Build the index.
centrifuge-build -p $N --conversion-table $TABLE --taxonomy-tree $NODES  --name-table $NAMES  $REFERENCE $INDEX >> $RUNLOG

# Perform the classification.

{% if library.value == "SE" %}
    # Run centrifuge in single-end mode.
    cat ${SHEET} | parallel --header : --colsep , -j $N  "centrifuge -x  $INDEX -U $DDIR/{read1} --min-hitlen $HITLEN -S $COUNTSDIR/{sample}.rep --report-file  $COUNTSDIR/{sample}.tsv 2>> $RUNLOG"
{% else %}
    # Run centrifuge un paired-end mode.
    cat ${SHEET} | parallel --header : --colsep , -j $N  "centrifuge -x  $INDEX -1 $DDIR/{read1} -2 $DDIR/{read2} --min-hitlen $HITLEN -S $COUNTSDIR/{sample}.rep --report-file  $COUNTSDIR/{sample}.tsv 2>> $RUNLOG"
{% endif %}

set +e
# Generate an individual kraken style reports for each sample
# This will raise an error on no hits, hence we turn of error checking.
ls -1 $COUNTSDIR/*.rep | parallel -j $N "centrifuge-kreport -x $INDEX {} > $COUNTSDIR/{/.}.txt 2>> $RUNLOG"
set -e

# Generate a combined reformatted report of kraken reports inside of classification directory.
python -m recipes.code.combine_centrifuge_reports --cutoff $CUTOFF $COUNTSDIR/*.txt --outdir $CLASSDIR --is_kreport

# Draw the heat maps for each csv report
python -m recipes.code.plotter $CLASSDIR/*.csv --type heat_map

# Generate a combined reformatted report of kraken reports tabulating the third column
python -m recipes.code.combine_centrifuge_reports $COUNTSDIR/*.txt --idx 2 --outdir $CLASSDIR --is_kreport


# Draw the rarefaction curves.
python -m recipes.code.rarefaction $COUNTSDIR/*.rep --outdir $RAREFACTION

# Extract unclassified reads into separate folder.
python -m recipes.code.extract_unclassified $DDIR/*.fastq.gz --report_files $COUNTSDIR/*.rep --outdir $UNCLASS

# Zip the unclassified reads
zip -q -r $UNCLASS.zip $UNCLASS

# Cleanup unzipped reads
rm -rf $UNCLASS/*
