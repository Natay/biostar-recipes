import sys, os, csv


def check_sample_sheet(data_dir, fname):
    stream = csv.DictReader(open(fname), delimiter=",")
    error_list = []

    for row in stream:
        fname1, fname2 = row['read1'], row['read2']

        file1 = os.path.join(data_dir, fname1)
        file2 = os.path.join(data_dir, fname2)

        if not os.path.isfile(file1):
            error_list.append(fname1)
        if not os.path.isfile(file2):
            error_list.append(fname2)

        if error_list:
            print("Error in the sample sheet in following files. Exiting")
            for fname in error_list:
                print(fname)
            sys.exit(1)
        else:
            sys.exit(0)


if __name__ == "__main__":
    data_dir = sys.argv[1]
    fname = sys.argv[2]
    check_sample_sheet(data_dir, fname)
