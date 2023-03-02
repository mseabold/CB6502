import argparse
import os

if __name__ == '__main__':
    parser = argparse.ArgumentParser()

    parser.add_argument('image')
    parser.add_argument('-s', '--start', type=int, default=0x1000)
    parser.add_argument('-p', '--pagesize', type=int, default=128)
    parser.add_argument('-o', '--output', default='image.ihex')

    args = parser.parse_args()

    with open(args.image, 'rb') as infile, open(args.output, 'w+') as outfile:
        addr = args.start

        data = infile.read(args.pagesize)

        while data:
            check = len(data)

            outfile.write(':')
            outfile.write('{:02X}'.format(check))

            outfile.write('{:02X}'.format(addr & 0xFF))
            outfile.write('{:02X}'.format((addr >> 8) & 0xFF))

            check += (addr & 0xFF)
            check += (addr >> 8 ) & 0xFF

            outfile.write('00')

            for b in data:
                bi = int(b)
                outfile.write('{:02X}'.format(bi))
                check += bi

            check &= 0xFF
            check ^= 0xFF
            check += 1
            check &= 0xFF

            outfile.write('{:02X}\n'.format(check))

            addr += len(data)
            data = infile.read(args.pagesize)

        outfile.write(':00000001FF')
