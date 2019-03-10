set -ueo pipefail

#Table of contents
TOC={{reads.toc}}
LIBRARY={{library.value}}
QUALITY_SCORE={{quality.value}}
WINDOW_SIZE={{window.value}}
ADAPTER={{adapter.value}}
MINIMUMLENGTH={{minLength.value}}

#Create file list
cat ${TOC} | egrep 'fastq|fq'|sort >files
INPUTS=files

# The directory that contains the preliminary reports.
mkdir -p before_trimming_fastqc_reports


# Add extra flags if the group parameter was selected.
if [ "{{group.value}}" == "nogroup" ]; then
    FLAGS="--nogroup"
else
    FLAGS=""
fi

# Run fastqc on selected files.
cat ${INPUTS}| parallel fastqc -q ${FLAGS} {} -o before_trimming_fastqc_reports


#Output for trimmed files
mkdir -p output


#Adapter sequence fasta file for illumina clip
printf ">adapter sequence \n"%s"" ${ADAPTER} >adapter.fa

# Run trimmomatic

if [ "$ADAPTER" == "No_adapter" ] && [ "$LIBRARY" == "SE" ]; then
    cat ${INPUTS} | parallel trimmomatic SE {} ./output/{1/.}_trimmed.fq SLIDINGWINDOW:${WINDOW_SIZE}:${QUALITY_SCORE} MINLEN:${MINIMUMLENGTH}
fi

if [ "$ADAPTER" == "No_adapter" ] && [ "$LIBRARY" == "PE" ]; then
    cat ${INPUTS} | parallel -N 2 "trimmomatic PE {1} {2} ./output/{1/.}_paired.fq ./output/{1/.}_unpaired.fq ./output/{2/.}_paired.fq  ./output/{2/.}_unpaired.fq SLIDINGWINDOW:${WINDOW_SIZE}:${QUALITY_SCORE} MINLEN:${MINIMUMLENGTH}"
fi


if [ "$ADAPTER" != "No_adapter" ] &&  [ "$LIBRARY" == "SE" ]; then
    cat ${INPUTS}| parallel trimmomatic SE {} ./output/{1/.}_trimmed.fq  ILLUMINACLIP:adapter.fa:2:30:10 SLIDINGWINDOW:${WINDOW_SIZE}:${QUALITY_SCORE} MINLEN:${MINIMUMLENGTH}
fi


if [ "$ADAPTER" != "No_adapter" ] &&  [ "$LIBRARY" == "PE" ]; then
    cat ${INPUTS}| parallel -N 2 "trimmomatic PE {1} {2} ./output/{1/.}_paired.fq ./output/{1/.}_unpaired.fq ./output/{2/.}_paired.fq  ./output/{2/.}_unpaired.fq ILLUMINACLIP:adapter.fa:2:30:10 SLIDINGWINDOW:${WINDOW_SIZE}:${QUALITY_SCORE} MINLEN:${MINIMUMLENGTH} "
fi


#Fastqc on the output
cd output

#file list of the trimmed files
ls > file_list.txt

# Report directory.
mkdir -p after_trimming_fastqc_reports

#Running fastqc on reported files
cat file_list.txt | egrep 'fastq|fq' | parallel fastqc -q ${FLAGS} {} -o after_trimming_fastqc_reports



