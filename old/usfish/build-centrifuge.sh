# How to build a custom taxonony database

# Gnathostomata (jawed vertebrates)
ID=7776

ACC=acc.txt
SEQ=sequences.fa
TAXDIR=/export/refs/taxonomy
INDEX=/export/refs/centrifuge/7776

mkdir -p index

# The lineage to be included.
taxonkit list --ids ${ID} --indent "" | sort > targets.txt

# The lineage to be excluded
# Mammalia (mammals), class
taxonkit list --ids 40674 --indent "" | sort > remove.txt

# Keep only the elements in targets/txt and not in remove.txt
comm -2 -3 targets.txt remove.txt  > selected.txt

# Download and unpack in $TAXDIR
# wget ftp://ftp.ncbi.nlm.nih.gov/pub/taxonomy/taxdump.tar.gz

# Export and unpack in current directory
# wget ftp://ftp.ncbi.nih.gov/pub/taxonomy/accession2taxid/nucl_gb.accession2taxid.gz
# gunzip nucl_gb.accession2taxid.gz

# Parse the accession numbers to keep only the selected taxa.
python select-taxa.py > accession.txt

# Extract the selected ids into a separate file.
cat accession.txt| parallel --pipe --block 1k blastdbcmd -db /export/refs/nt/nt -entry_batch - > sequences.fa

# Build the custom database with centrifuge.
centrifuge-build -p 4 --conversion-table selected.txt --taxonomy-tree $TAXDIR/nodes.dmp --name-table $TAXDIR/names.dmp sequences.fa $INDEX >/dev/null


