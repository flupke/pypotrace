from potrace._potrace cimport *
cimport cpython.bytes

import math
from idlelib.paragraph import reformat_paragraph

unit = 10
column_count = 75

def unit_func(potrace_dpoint_s p):
  x = math.floor(p.x * unit +.5)
  y = math.floor(p.y * unit +.5)
  return x, y

cdef svg_moveto(potrace_dpoint_s p):
  x, y = unit_func(p)
  return "M%ld %ld " % (x, y), 'M', x, y


cdef svg_rmoveto(potrace_dpoint_s p, int cur_x, int cur_y):
  x, y = unit_func(p)
  return "m%ld %ld " % (x-cur_x, y-cur_y), 'm', x, y


cdef svg_lineto(potrace_dpoint_s p, str lastop, int cur_x, int cur_y):
  result = ""
  x, y = unit_func(p)

  if lastop != 'l':
    result += "l%ld %ld " % (x-cur_x, y-cur_y)
  else:
    result += "%ld %ld " % (x-cur_x, y-cur_y)

  return result, 'l', x, y

cdef svg_curveto(potrace_dpoint_s p1, potrace_dpoint_s p2, potrace_dpoint_s p3, str lastop, int cur_x, int cur_y):
    result = ""
    q1_x, q1_y = unit_func(p1)
    q2_x, q2_y, = unit_func(p2)
    q3_x, q3_y = unit_func(p3)

    if lastop != 'c':
        result += "c%ld %ld %ld %ld %ld %ld " % (q1_x-cur_x, q1_y-cur_y, q2_x-cur_x, q2_y-cur_y, q3_x-cur_x, q3_y-cur_y)
    else:
        result += "%ld %ld %ld %ld %ld %ld " % (q1_x-cur_x, q1_y-cur_y, q2_x-cur_x, q2_y-cur_y, q3_x-cur_x, q3_y-cur_y)
    return result, 'c', q3_x, q3_y


cdef svg_path(potrace_curve_s *curve, int abs):
    result = ""
    s, lastop, cur_x, cur_y = svg_moveto(curve.c[curve.n-1][2])
    result += s

    for i in range(curve.n):
        c1 = curve.c[i][0]
        c2 = curve.c[i][1]
        end_point = curve.c[i][2]
        if curve.tag[i] == POTRACE_CURVETO:
            s, lastop, cur_x, cur_y = svg_curveto(c1, c2, end_point, lastop, cur_x, cur_y)
            result += s
        elif curve.tag[i] == POTRACE_CORNER:
            s, lastop, cur_x, cur_y = svg_lineto(c2, lastop, cur_x, cur_y)
            result += s
            s, lastop, cur_x, cur_y = svg_lineto(end_point, lastop, cur_x, cur_y)
            result += s

    return result[:-1] + "z"


cdef write_paths_transparent_rec(potrace_path_s *tree):

    cdef potrace_path_s *cur_path = tree
    if cur_path == NULL:
        return ""

    result = ""
    while cur_path != NULL:
        result += "<path d=\""
        result += svg_path(&cur_path.curve, 1)
        q = cur_path.childlist
        if q != NULL:
            while q != NULL:
                result += svg_path(&q.curve, 0)
                q = q.sibling

        result += "\"/>"
        result = reformat_paragraph(result, column_count) + "\n"
        q = cur_path.childlist
        if q != NULL:
            while q != NULL:
                result += write_paths_transparent_rec(q.childlist)
                q = q.sibling
        cur_path = cur_path.sibling

    return result

cdef str page_svg(potrace_path_s *plist, potrace_bitmap_s *bm):

    b_w = bm.w
    b_h = bm.h
    if bm.w == 0:
        b_w = 1

    if bm.h == 0:
        b_h = 1


    bboxx = b_w
    bboxy = b_h
    origx = 0
    origy = 0
    scalex = 1 / unit
    scaley = 1 / unit
    color = 0x000000

    result = ""
    result += "<?xml version=\"1.0\" standalone=\"no\"?>\n"
    result += "<!DOCTYPE svg PUBLIC \"-//W3C//DTD SVG 20010904//EN\"\n"
    result += " \"http://www.w3.org/TR/2001/REC-SVG-20010904/DTD/svg10.dtd\">\n"

    result += "<svg version=\"1.0\" xmlns=\"http://www.w3.org/2000/svg\"\n"
    result += " width=\"%fpt\" height=\"%fpt\" viewBox=\"0 0 %f %f\"\n" % (bboxx, bboxy, bboxx, bboxy)
    result += " preserveAspectRatio=\"xMidYMid meet\">\n"
    result += "<metadata>\n"
    result += "Created by potrace " + cpython.bytes.PyBytes_FromString(potrace_version()).decode() +", written by Peter Selinger 2001-2015\n"
    result += "</metadata>\n"
    result += "<g transform=\""

    if origx != 0 or origy != 0:
        result += "translate(%f,%f) " % (origx, origy)

    result += "scale(%f,%f)" % (scalex, scaley)
    result += "\"\n"
    result += "fill=\"#%06x\" stroke=\"none\">\n" % color

    result += write_paths_transparent_rec(plist).strip()
    result += "\n</g>\n"
    result += "</svg>"
    return result