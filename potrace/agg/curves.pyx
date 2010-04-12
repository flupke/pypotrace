cimport potrace.agg.basics as agg


cdef unsigned num_vertices(curve4_div *curve):
    cdef unsigned count = 0
    cdef double x, y
    curve.rewind(0)
    while curve.vertex(&x, &y) != agg.path_cmd_stop:
        count += 1
    return count
