TESTTTTTT

#
# Set a logfile destination.
#
set.logfile(name=analysis.log, append=T)

#
# This will the folder for the final results.
#
system(mkdir -p output)

# Set the input dir from the data, output to scratch.
set.dir(input={{input.data_dir}}, output=scratch)

#
# Link the required data directories into the job folder.
#
system(ln -s {{input.data_dir}}/reads, .)

#
# Copy the reference file to scratch so that we can operate on it later.
#
system(cp {{input.data_dir}}/reference/* scratch)

#
# Create contigs out of raw paired end sequence data
#
make.contigs(file=inputs.txt, processors=2)

# Use the scratch as input.
set.dir(input=scratch, output=scratch)

#
# Report statistics on the sequences.
#
summary.seqs(fasta=inputs.trim.contigs.fasta)

#
# Filter out long reads and mismatches
#
screen.seqs(fasta=inputs.trim.contigs.fasta, group=inputs.contigs.groups, maxambig=0, maxlength=320)

#
# Reduce data to unique sequences.
#
unique.seqs(fasta=inputs.trim.contigs.good.fasta)

#
# Create a count file.
#
count.seqs(name=inputs.trim.contigs.good.names, group=inputs.contigs.good.groups)

#
# Edit the silva.bacteria.fasta file to only include the V4 region.
#
pcr.seqs(fasta=silva.bacteria.fasta, start=11894, end=25319, keepdots=F, processors=8)

#
# Align to reference file.
#
align.seqs(fasta=inputs.trim.contigs.good.unique.fasta, reference=silva.bacteria.pcr.fasta, flip=t)

#
# Repor statistics on the sequences.
#
summary.seqs(fasta=inputs.trim.contigs.good.unique.align, count=inputs.trim.contigs.good.count_table)

#
# Screen alignment for mismatches and errors.
#
screen.seqs(fasta=inputs.trim.contigs.good.unique.align, count=inputs.trim.contigs.good.count_table, start=1, end=13424, maxhomop=8)

#
# Remove columns where there is no match in any sequence.
#
filter.seqs(fasta=inputs.trim.contigs.good.unique.good.align, vertical=t)

#
# Reduce to a unique subset.
#
unique.seqs(fasta=inputs.trim.contigs.good.unique.good.filter.fasta, count=inputs.trim.contigs.good.good.count_table)

#
# Cluster reads to combine similar sequences
#
pre.cluster(fasta=inputs.trim.contigs.good.unique.good.filter.unique.fasta, count=inputs.trim.contigs.good.unique.good.filter.count_table, diffs=2)

#
# Mark chimeras.
#
chimera.uchime(fasta=inputs.trim.contigs.good.unique.good.filter.unique.precluster.fasta, count=inputs.trim.contigs.good.unique.good.filter.unique.precluster.count_table, dereplicate=t)

#
# Remove the marked sequences.
#
remove.seqs(fasta=inputs.trim.contigs.good.unique.good.filter.unique.precluster.fasta, accnos=inputs.trim.contigs.good.unique.good.filter.unique.precluster.denovo.uchime.accnos)

#
# Copy the final result files to simpler names.
#
system(cp scratch/inputs.trim.contigs.good.unique.good.filter.unique.precluster.pick.fasta scratch/final.fasta)
system(cp scratch/inputs.trim.contigs.good.unique.good.filter.unique.precluster.denovo.uchime.pick.count_table scratch/final.count)

#
# Classify sequences
#
classify.seqs(fasta=final.fasta, count=final.count, reference=trainset9_032012.pds.fasta, taxonomy=trainset9_032012.pds.tax, cutoff=75)

#
# For GUniFrac analysis, first make a distance file.
#
dist.seqs(fasta=final.fasta, output=lt, processors=2)

#
# Then create a phylogenic tree
#
clearcut(phylip=final.phylip.dist)

#
# Moving the final results into the output folder
#
system(cp scratch/final* output)


