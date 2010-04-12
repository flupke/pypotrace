cimport numpy as np
from potrace.agg cimport curves as agg

import numpy as np


cdef np.ndarray bezier(np.ndarray p_, int steps=30):
    """
    Calculate a bezier curve from the 4 control points defined in the numpy
    array *p*.

    Returns a numpy array containing *steps + 1* vertices equally spaced along
    the curve.
    
    The function uses the forward differencing algorithm described here:
    http://www.niksula.cs.hut.fi/~hkankaan/Homepages/bezierfast.html
    """
    cdef double t = 1.0 / steps
    cdef double temp = t * t
    cdef np.ndarray[np.double_t, ndim=2] p=p_, points
    cdef np.ndarray[np.double_t, ndim=1] f, fd, fdd_per_2, fddd_per_2, fddd, \
            fdd, fddd_per_6
    
    f = p[0].copy()
    fd = 3 * (p[1] - p[0]) * t
    fdd_per_2 = 3 * (p[0] - 2 * p[1] + p[2]) * temp
    fddd_per_2 = 3 * (3 * (p[1] - p[2]) + p[3] - p[0]) * temp * t
    
    fddd = 2 * fddd_per_2
    fdd = 2 * fdd_per_2
    fddd_per_6 = fddd_per_2 / 3.0
    
    points = np.empty((steps + 1, 2))
    for i in range(steps + 1):
        points[i] = f
        f += fd + fdd_per_2 + fddd_per_6
        fd += fdd + fddd_per_2
        fdd += fddd
        fdd_per_2 += fddd_per_2

    return points


cdef np.ndarray adaptive_bezier(np.ndarray p):
    """
    Tesselate a bezier curve adaptively
    """
    cdef agg.curve4_div *curve
    cdef np.ndarray[np.double_t, ndim=2] points
    cdef int i, num_vertices
    curve = agg.new_curve4_div(p[0][0], p[0][1],
            p[1][0], p[1][1],
            p[2][0], p[2][1],
            p[3][0], p[3][1])
    num_vertices = agg.num_vertices(curve)
    points = np.empty((num_vertices, 2))
    curve.rewind(0)
    for i in range(num_vertices):
        curve.vertex(&points[i, 0], &points[i, 1])
    agg.delete_curve4_div(curve)
    return points

