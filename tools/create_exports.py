import argparse
import sys
import re

linkersym = re.compile(r'^__.*__$')

def parse_export(cols, output, filter_linkersyms):
    sym = cols[0]
    addr = int(cols[1], 16)
    typ = cols[2]

    if 'L' in typ:
        if not filter_linkersyms or not linkersym.fullmatch(sym):
            output.write('{} := ${:04x}\n'.format(sym, addr))

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('mapfile', type=argparse.FileType('r'))
    parser.add_argument('-o','--output',type=argparse.FileType('w'), default=sys.stdout)
    parser.add_argument('-f', '--filter-linkersyms', action='store_true', dest='filter')
    parser

    args = parser.parse_args()

    with args.mapfile, args.output:
        exports_found = False
        line = args.mapfile.readline()

        while line:
            if line.strip() == 'Exports list by name:':
                exports_found = True
                break

            line = args.mapfile.readline()

        if not exports_found:
            raise ValueError('Unable to locate exports in mapfile')

        args.mapfile.readline()

        line = args.mapfile.readline()

        while line and len(line.strip()) > 0:
            line = line.strip()
            cols = line.split()

            numcols = len(cols)

            if numcols != 3 and numcols != 6:
                raise ValueError('Expected 3 or 6 columns for export line: {}'.format(line))

            parse_export(cols, args.output, args.filter)

            if numcols == 6:
                parse_export(cols[3:], args.output, args.filter)

            line = args.mapfile.readline()

