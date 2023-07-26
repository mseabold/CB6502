import struct
import argparse
import os

PAGE_SIZE = 64

# Num Pages: 4 Octets
MAIN_HEADER = struct.Struct('<HH')

# Page Address: 2 Octets
# Write Offset: 1 Octet
# Write Length: 1 Octet
PAGE_HEADER = struct.Struct('<HBB')

if __name__ == '__main__':
    parser = argparse.ArgumentParser()

    parser.add_argument('image', help='boot image output')
    parser.add_argument('map', help='map file for the boot image')

    parser.add_argument('-s', '--start', help='symbol name for ROM start', default='__ROM_START__')
    parser.add_argument('-e', '--end', help='symbold name for ROM end', default='__ROM_LAST__')
    parser.add_argument('-a', '--romaddr', help='address of ROM in memory', type=int, default=0x8000)
    parser.add_argument('-v', '--vectors', help='include vectors', action='store_true')
    parser.add_argument('-o', '--output', default='update.bin')
    parser.add_argument('-p', '--sdp', help='flag SDP as enabled on ROM chip', action='store_true')

    args = parser.parse_args()

    with open(args.image, 'rb') as infile, open(args.map, 'r') as mapfile, open(args.output, 'wb+') as outfile:
        regions = []

        line = mapfile.readline()

        while line and line.strip() != 'Exports list by name:':
            line = mapfile.readline()

        if not line:
            raise ValueError('Unable to locate export list')

        # Read the list header out
        mapfile.readline()

        line = mapfile.readline()

        symmap = {}

        while line and len(line.strip()) > 0:
            fields = line.strip().split()

            if len(fields) != 3 and len(fields) != 6:
                raise ValueError('Invalid export line: {}, '.format(line.strip(), fields))

            symmap[fields[0]] = int(fields[1], 16)

            if len(fields) == 6:
                symmap[fields[3]] = int(fields[4], 16)

            line = mapfile.readline()

        start = symmap.get(args.start)
        end = symmap.get(args.end)

        if not start or not end:
            raise ValueError('Unable to find start and stop symbols')

        outfile.seek(MAIN_HEADER.size)

        numpages = 0

        addr = start
        infile.seek(start - args.romaddr, 0)

        while addr <= end:
            offset = addr & 0x3f
            addr = addr & 0xffc0

            sz = PAGE_SIZE - offset

            if sz > end - addr + 1:
                sz = end - addr + 1

            bindata = infile.read(sz)

            if len(bindata) != sz:
                raise ValueError('ROM image missing data')

            outfile.write(PAGE_HEADER.pack(addr, offset, sz))
            outfile.write(bindata)

            addr += PAGE_SIZE
            numpages += 1

        if args.vectors:
            infile.seek(0xfffa - args.romaddr)
            vecdata = infile.read(6)

            outfile.write(PAGE_HEADER.pack(0xffc0, 0x3a, 6))
            outfile.write(vecdata)

        flags = 0

        if args.sdp:
            flags |= 1

        outfile.seek(0, 0)
        outfile.write(MAIN_HEADER.pack(numpages, flags))
