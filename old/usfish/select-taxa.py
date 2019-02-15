import csv, sys

selected = set()
for taxid in open('work/selected.txt'):
    taxid = taxid.strip()
    selected.add(taxid)

fname = 'work/nucl_gb.accession2taxid'
stream = open(fname, 'rt')
head = next(stream)
print (head)
for acc, vers, taxid, gi in csv.reader(stream, delimiter="\t"):
    if taxid in selected:
        print(acc)
