set -ue

# The table of contents contains all files in the collection.
INPUTS={{reads.toc}}

# Select flags
GROUP={{group.value}}

# Summarize the results with multiqc.
SUMMARIZE={{summarize.value}}

# The directory that contains the reports.
mkdir -p results

# Add extra flags if the group parameter was selected.
if [ "${GROUP}" == "nogroup" ]; then
    FLAGS="--nogroup"
else
    FLAGS=""
fi

# Run fastqc on selected files.
cat ${INPUTS} | egrep 'fastq|fq' | parallel fastqc -q ${FLAGS} {} -o results

echo ${SUMMARIZE}

# Run multiqc if requested.
if [ "${SUMMARIZE}" == "True" ]; then
    multiqc -o multiqc results
fi
