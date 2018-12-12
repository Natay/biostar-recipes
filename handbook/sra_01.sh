# This recipe download sequencing data from SRA
# then performs quality control on it.

# Stop the script on errors.
set -ue

# Set the SRA number.
SRA=SRR519926

# How many sequences to unpack.
N=10000

# Create directory to store the reads in.
mkdir -p reads

# Download 1000 reads from SRA.
fastq-dump --split-files -X $N -O reads  $SRA

# Make a directory for the fastqc reports
mkdir -p reports

# Run the fastqc report on the sra reads.
fastqc reads/*.fastq -o reports

# Create the adapter sequence used for trimming.
echo ">illumina" > adapter.fa
echo "AGATCGGAAGAGCACACGTCTGAACTCCAGTCAC" >> adapter.fa

# Run trimmomatic on the data.
trimmomatic PE reads/${SRA}_1.fastq reads/${SRA}_2.fastq -baseout reads/${SRA}.trimmed.fq  ILLUMINACLIP:adapter.fa:2:30:5 SLIDINGWINDOW:4:20

# Run trimmomatic on the trimmed data.
fastqc reads/*.fq -o reports

# Delete the fastqc zip files to reduce clutter.
rm -f reports/*.zip
