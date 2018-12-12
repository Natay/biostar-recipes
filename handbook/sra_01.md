Summary: Perform data quality control on FASTQ data

This recipe performs data quality control steps on data obtained from SRA.

Tools used: [fastq-dump][sra] from the [SRA toolkit][sra],  [trimmomatic][trimmomatic], [fastqc][fastqc]

[sra]: https://www.ncbi.nlm.nih.gov/sra/docs/toolkitsoft/
[trimmomatic]: http://www.usadellab.org/cms/?page=trimmomatic
[fastqc]: https://www.bioinformatics.babraham.ac.uk/projects/fastqc/

Methodology:

1. Download data with `fastq-dump`
1. Run `fastqc` on the sequencing reads
1. Creates an adapter file that matches the library construction.
1. Run `trimmomatic` to trim reads by quality and remove adapter sequences
1. Run `fastqc` on trimmed data

The recipe will download the data into separate directories to allow you to keep track of the files a little better.
