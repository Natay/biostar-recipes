# Stop on any error.
set -ue

# Assembly scaffolds.
SEQUENCE={{sequence.value}}

# Species to be used as training set.
SPECIES={{species.value}}

# Augustus results directory.
RESULTS_DIR={{runtime.work_dir}}/results

# Create AUGUSTUS directory.
mkdir -p $RESULTS_DIR

# Result files.
GENES=${RESULTS_DIR}/annotations.txt

# The protein file.
PROTEINS=${RESULTS_DIR}/proteins.fa

# Augustus configuration path location.
export AUGUSTUS_CONFIG_PATH=/export/src/augustus/config

# Run the Augustus on the sequence.
augustus --species=$SPECIES $SEQUENCE > $GENES

# Make the proteins.fa file from the Augustus predicted GTF file.
getAnnoFasta.pl $GENES

# Change the name of the output.
mv ${RESULTS_DIR}/annotations.aa ${PROTEINS}

# Print the first few lines.
cat $GENES | head -75

