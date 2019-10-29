from nose.tools import assert_equal
import numpy as np
import potrace


circle_xml = '<?xml version="1.0" standalone="no"?>\n' \
            '<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 20010904//EN"\n' \
            ' "http://www.w3.org/TR/2001/REC-SVG-20010904/DTD/svg10.dtd">\n' \
            '<svg version="1.0" xmlns="http://www.w3.org/2000/svg"\n' \
            ' width="32.000000pt" height="32.000000pt" viewBox="0 0 32.000000 32.000000"\n' \
            ' preserveAspectRatio="xMidYMid meet">\n' \
            '<metadata>\n' \
            'Created by potrace {}, written by Peter Selinger 2001-2015\n' \
            '</metadata>\n' \
            '<g transform="scale(0.100000,0.100000)"\n' \
            'fill="#000000" stroke="none">\n' \
            '<path d="M133 235 c-62 -26 -59 -120 4 -143 67 -23 125 40 98 105 -17 40 -60\n' \
            '56 -102 38z"/>\n' \
            '</g>\n' \
            '</svg>'


def test_to_xml():
    # Make a circle
    data = np.zeros((32, 32), np.uint32)
    radius2 = 8 * 8
    for j in range(32):
        y = j - 16
        for i in range(32):
            x = i - 16
            if x * x + y * y > radius2:
                data[j, i] = 0
            else:
                data[j, i] = 1

    # Trace it
    bmp = potrace.Bitmap(data)
    bmp.trace()
    version = potrace.potracelib_version()
    xml = circle_xml.format(version)
    assert_equal(xml, bmp.to_xml())