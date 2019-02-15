import pysam
import sys
''
def run(args):

    bam = pysam.AlignmentFile("-")
    out = pysam.AlignmentFile("-", "w", template=bam)

    minlen = args.minlen

    for aln in bam:
        if aln.query_alignment_length > minlen:
            out.write(aln)


def main():
    from argparse import ArgumentParser

    parser = ArgumentParser()

    parser.add_argument('--minlen', default=100, help="Minimal alignment length.", type=int,)

    args = parser.parse_args()

    run(args)

if __name__ == '__main__':
    main()


