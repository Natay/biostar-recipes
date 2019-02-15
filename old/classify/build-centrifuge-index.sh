#
# Builds custom centrifuge database from a FASTA file.
#
# The FASTA file sequence names must be accession numbers.
#

# The input fasta file that contains the sequences.
INPUT=fishacc.fa

# The location of the taxonomy files.
TAXDIR=/export/refs/taxonomy

# The name of the output index
INDEX=index/fishdb

# Download taxonomy specific files. Run these in  $TAXDIR.
# This operation only needs to be done once.
#
# (cd $TAXDIR && wget ftp://ftp.ncbi.nlm.nih.gov/pub/taxonomy/taxdump.tar.gz)
# (cd $TAXDIR && wget ftp://ftp.ncbi.nih.gov/pub/taxonomy/accession2taxid/nucl_gb.accession2taxid.gz)
# (cd $TAXDIR && gunzip taxdump.tar.gz)
# (cd $TAXDIR && gunzip nucl_gb.accession2taxid.gz)
# Create the conversion table (accession to taxid mapping).
# cat $TAXDIR/nucl_gb.accession2taxid | cut -f 1,3 > $TAXDIR/table.txt

# Create the directory for the index.
mkdir -p index

# Build the custom database with centrifuge.
TABLE=$TAXDIR/table.txt
NODES=$TAXDIR/nodes.dmp
NAMES=$TAXDIR/names.dmp
N=4

# Build the index.
centrifuge-build -p $N --conversion-table $TABLE --taxonomy-tree $NODES  --name-table $NAMES  $INPUT $INDEX


