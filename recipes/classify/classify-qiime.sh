set -ue

set_env()
{

export CONDA_PS1_BACKUP=""
export JAVA_LD_LIBRARY_PATH=""
export PS1=""
export CONDA_PATH_BACKUP=""
export CONDA_PREFIX=""
export JAVA_HOME_CONDA_BACKUP=""
export JAVA_HOME=""

# This is needed only in Linux machine.
export LC_ALL=C.UTF-8
export LANG=C.UTF-8

}

# The input directory for the data
DDIR=$(dirname {{reads.value}})
FILE=$(basename {{reads.value}})

# Unzip if the data is zipped
if [[ $FILE == *.zip ]]; then
echo "unzipping"
unzip $DDIR/$FILE -d $DDIR/data
DDIR=$DDIR/data
fi

# Library type of input reads.
LIBRARY={{library.value}}

# Sample Metadata file.
SAMPLE_SHEET={{sheet.value}}

# Position at which forward read sequences to be truncated from at 3' end.
POS_RIGHT_F={{trunc_right_f.value}}

#Position at which reverse read sequences to be truncated from at 3' end.
POS_RIGHT_R={{trunc_right_r.value}}

#Position until which forward read sequences to be truncated from at 5' end.
POS_LEFT_F={{trunc_left_f.value}}

#Position until which reverse read sequences to be truncated from at 5' end.
POS_LEFT_R={{trunc_left_r.value}}

# No. of threads to use.
N=4

# Create main store for results.
STORE=results
mkdir -p $STORE

# Directory that holds input data as qiime2 artifact.
DATA=$STORE/data
mkdir -p $DATA

# Directory that holds DADA2 results
DADA2=$STORE/dada2

# Directory that holds BLAST+ taxonomy classification results.
BLAST=$STORE/classified

# The reference sequence to classify against.
REF_FASTA={{reference.value}}


TAXDIR=/export/refs/taxonomy
#
# Download taxonomy specific files and create taxonomy lineage database using the script below.
# This operation only needs to be done only once for the entire website.
# It will create 'taxon_db' database in $TAXDIR.
# python -m recipes.code.taxon_lineage --taxdir $TAXDIR
#
DBPATH=$TAXDIR/lineage_db

# Collect accessions from reference fasta.
cat $REF_FASTA | grep ">" | sed 's/ .*$//g' |sed 's/>//g' >$DATA/accessions.txt

# Create taxonomy file.
python -m recipes.code.get_taxa_lineage --dbpath $DBPATH --accessions $DATA/accessions.txt --outfile $DATA/taxonomy.tsv

# Convert sample sheet to a tsv file with .
SHEET=$DATA/metadata.tsv
cat $SAMPLE_SHEET | awk 'BEGIN{FS=",";OFS="\t"}{ if(NR==1) {$1="sampleid"; print} else {print}}'| tr "," "\t"  >$SHEET

# Set the environment variables and switch to qiime2 environment,
set_env
source activate /home/www/miniconda3/envs/qiime2

# Convert reference file to qiime2 artifact.
echo "Converting reference to qiime2 format"
REFERENCE=$DATA/refs.qza
qiime tools import --input-path $REF_FASTA --output-path $REFERENCE --type 'FeatureData[Sequence]'


# Convert taxonomy file to qiime 2 artifact.
TAXONOMY=$DATA/taxonomy.qza
qiime tools import --input-path $DATA/taxonomy.tsv --output-path $TAXONOMY --type FeatureData[Taxonomy]


# Import the input files as a qiime2 artifact.
echo "Importing data as qiime2 artifact."


{% if library.value == "SE" %}

qiime tools import --type 'SampleData[SequencesWithQuality]'  --input-path $DDIR \
--source-format CasavaOneEightSingleLanePerSampleDirFmt --output-path $DATA/data.qza

{% else %}

qiime tools import --type 'SampleData[PairedEndSequencesWithQuality]'  --input-path $DDIR \
--source-format CasavaOneEightSingleLanePerSampleDirFmt --output-path $DATA/data.qza

{% endif %}

echo "Generating summary data."
qiime demux summarize --i-data $DATA/data.qza --o-visualization $DATA/data.qzv

# De-noising with Dada2 and feature table generation.
echo "De-noising with dada2. "

{% if library.value == "SE" %}

(time qiime dada2 denoise-single --verbose  --i-demultiplexed-seqs $DATA/data.qza --output-dir $DADA2 --p-n-threads $N \
--p-trunc-len $POS_RIGHT_F --p-trim-left $POS_LEFT_F ) 2>&1

{% else %}

(time qiime dada2 denoise-paired --verbose  --i-demultiplexed-seqs $DATA/data.qza --output-dir $DADA2 --p-n-threads $N \
--p-trunc-len-f $POS_RIGHT_F --p-trunc-len-r $POS_RIGHT_R --p-trim-left-f $POS_LEFT_F --p-trim-left-r $POS_LEFT_R ) 2>&1

{% endif %}

echo "Making FeatureTable files."
qiime feature-table summarize --i-table $DADA2/table.qza --o-visualization $DADA2/table.qzv --m-sample-metadata-file $SHEET

echo "Making FeatureData files"
qiime feature-table tabulate-seqs --i-data $DADA2/representative_sequences.qza --o-visualization $DADA2/representative_sequences.qzv

# Taxonomy classification.
echo "Running classify-consensus-blast taxonomy assignment."
qiime feature-classifier classify-consensus-blast --i-query $DADA2/representative_sequences.qza --i-reference-reads $REFERENCE \
--i-reference-taxonomy $TAXONOMY --p-evalue 1e-11 --p-strand plus --p-maxaccepts 1 --p-perc-identity 0.99 --output-dir $BLAST --verbose

echo "Generating visualization of classification.qza taxonomy file"
qiime metadata tabulate --m-input-file $BLAST/classification.qza --o-visualization $BLAST/classification.qzv

# Generate a bar plot of classification.
qiime taxa barplot --i-table $DADA2/table.qza --i-taxonomy $BLAST/classification.qza --m-metadata-file $SHEET --o-visualization $STORE/taxa-bar-plots.qzv

for id in $(seq 1 7)
do
# Create collapsed table at species level.
qiime taxa collapse  --i-table $DADA2/table.qza --i-taxonomy $BLAST/classification.qza --p-level $id --o-collapsed-table $BLAST/taxa_level${id}_table.qza

qiime tools export --output-dir $BLAST $BLAST/taxa_level${id}_table.qza
biom convert -i $BLAST/feature-table.biom -o $BLAST/taxa_level${id}_table.txt --to-tsv
done

# Switch to engine environment.
set_env
source activate /home/www/miniconda3/envs/engine

for id in $(seq 1 7)
do
# Format table to create heatmaps. Creates *counts.csv and *perc.csv files.
python -m recipes.code.qiime_counts_to_csv --infile $BLAST/taxa_level${id}_table.txt --outdir $BLAST  --taxa-level $id

done

# Remove intermediate files.
rm -f $BLAST/*table*txt $BLAST/*table*qza

# Draw the heat maps for each csv report
python -m recipes.code.plotter $BLAST/*perc.csv --type heat_map

