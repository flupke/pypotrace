cimport numpy as np
cimport stdlib
from python_string cimport PyString_FromString

import numpy as np


# Number of pixels in a word
cdef int N = sizeof(potrace_word) * 8


class PotraceError(Exception): pass


cdef class Bitmap:
    """
    Represents a bitmap.

    The constructor *data* argument should be a 2D numpy array containing pixel
    data. Pixels are only interpreted as zero or nonzero.
    """

    cdef np.ndarray _data
    cdef potrace_bitmap_s po_bitmap

    def __init__(self, data):
        self.data = data

    def __cinit__(self):
        self.po_bitmap.map = NULL

    def __dealloc__(self):
        self.free_bitmap()

    def trace(self, turdsize=2, turnpolicy=POTRACE_TURNPOLICY_MINORITY,
            alphamax=1.0, opticurve=1, opttolerance=0.2, progress_func=None):
        """
        Trace the bitmap.

        Returns an Path instance containing the traced result.
        """
        cdef Parameters params = Parameters(turdsize=turdsize,
                turnpolicy=turnpolicy, alphamax=alphamax, opticurve=opticurve,
                opttolerance=opttolerance)
        # Trace bitmap
        ret = state_from_ptr(potrace_trace(params.po_params, &self.po_bitmap))
        if not ret.ok:
            raise PotraceError("error tracing bitmap")
        return ret.image

    property data:
        def __get__(self):
            return self._data

        def __set__(self, value):
            cdef int x, y
            self._data = value
            # Init potrace bitmap struct
            self.po_bitmap.w = self._data.shape[1]
            self.po_bitmap.h = self._data.shape[0]
            self.po_bitmap.dy = (self.po_bitmap.w + (
                (N - (self.po_bitmap.w & (N - 1))) & (N - 1))) / N
            # Allocate bitmap buffer
            size = self.po_bitmap.h * self.po_bitmap.dy * sizeof(potrace_word)
            self.free_bitmap()
            self.po_bitmap.map = <potrace_word*>stdlib.malloc(size)
            # Initialize bitmap buffer from numpy array
            for y in range(self.po_bitmap.h):
                for x in range(self.po_bitmap.w):
                    setpixel(&self.po_bitmap, x, y, bool(self._data[y, x]))

    cdef free_bitmap(self):
        if self.po_bitmap.map != NULL:
            stdlib.free(self.po_bitmap.map)


cdef class Parameters:
    """
    Stores parameters for the potrace_trace function.
    """
    
    cdef potrace_param_s *po_params

    def __cinit__(self, int turdsize=2, 
            int turnpolicy=POTRACE_TURNPOLICY_MINORITY, double alphamax=1.0, 
            int opticurve=1, double opttolerance=0.2):
        self.po_params = potrace_param_default()
        self.po_params.turdsize = turdsize
        self.po_params.turnpolicy = turnpolicy
        self.po_params.alphamax = alphamax
        self.po_params.opticurve = opticurve
        self.po_params.opttolerance = opttolerance

    def __dealloc__(self):
        potrace_param_free(self.po_params)


cdef class State:
    """
    Stores a potrace state struct.

    Normally created with the :func:`state_from_ptr` function.
    """

    cdef potrace_state_s *po_state

    def __cinit__(self):
        self.po_state = NULL

    def __dealloc__(self):
        if self.po_state != NULL:
            potrace_state_free(self.po_state)

    property ok:
        """
        This property is true if this State object stores a successful
        operation.
        """

        def __get__(self):
            if self.po_state == NULL:
                raise ValueError("can't query null state object")
            return self.po_state.status == POTRACE_STATUS_OK

    property image:
        """
        This property returns a Path containing a copy of this state's data.
        """

        def __get__(self):
            if not self.ok:
                raise ValueError("can't access the image property of "
                        "an incomplete trace state")
            return path_from_ptr(self.po_state.plist);            


cdef class BezierSegment:

    cdef potrace_dpoint_s _c1, _c2, _end_point

    property c1:
        def __get__(self):
            return (self._c1.x, self._c1.y)

    property c2:
        def __get__(self):
            return (self._c2.x, self._c2.y)

    property end_point:
        def __get__(self):
            return (self._end_point.x, self._end_point.y)

    def __repr__(self):
        return "BezierSegment(c1=%s, c2=%s, end_point=%s)" % (self.c1,
                self.c2, self.end_point)

    cdef load(self, potrace_dpoint_s *c1, potrace_dpoint_s *c2, 
            potrace_dpoint_s *end_point):
        """
        Load the segment from C structure pointers.
        """
        self._c1 = c1[0]
        self._c2 = c2[0]
        self._end_point = end_point[0]        


cdef class CornerSegment:

    cdef potrace_dpoint_s _c, _end_point

    property c:
        def __get__(self):
            return (self._c.x, self._c.y)

    property end_point:
        def __get__(self):
            return (self._end_point.x, self._end_point.y)

    def __repr__(self):
        return "CornerSegment(c=%s, end_point=%s)" % (self.c, self.end_point)

    cdef load(self, potrace_dpoint_s *c, potrace_dpoint_s *end_point):
        """
        Load the segment from C structure pointers.
        """        
        self._c = c[0]
        self._end_point = end_point[0]


cdef class Curve:

    cdef public object segments

    def __init__(self):
        self.segments = []

    property start_point:
        def __get__(self):
            return self.segments[-1].end_point

    def __iter__(self):
        return iter(self.segments)

    cdef append_bezier(self, potrace_dpoint_s *c1, potrace_dpoint_s *c2,
            potrace_dpoint_s *end_point):
        cdef BezierSegment seg = BezierSegment()
        seg.load(c1, c2, end_point)
        self.segments.append(seg)

    cdef append_corner(self, potrace_dpoint_s *c, potrace_dpoint_s *end_point):
        cdef CornerSegment seg = CornerSegment()
        seg.load(c, end_point)
        self.segments.append(seg)


cdef class Path:

    cdef object curves

    def __init__(self):
        self.curves = []

    cdef append_curve(self, potrace_curve_s *curve):
        cdef potrace_dpoint_s *c1, *c2, *end_point
        cdef Curve new_curve = Curve()
        for i in range(curve.n):
            c1 = &curve.c[i][0]
            c2 = &curve.c[i][1]
            end_point = &curve.c[i][2]
            if curve.tag[i] == POTRACE_CURVETO:
                new_curve.append_bezier(c1, c2, end_point)
            elif curve.tag[i] == POTRACE_CORNER:
                new_curve.append_corner(c2, end_point)
        self.curves.append(new_curve)

    def __iter__(self):
        return iter(self.curves)



def potracelib_version():
    """
    Return the potrace library version.
    """
    return PyString_FromString(potrace_version())


# Utility functions

cdef void setpixel(potrace_bitmap_s *bmp, int x, int y, int on):
    """
    Set a pixel on or off in a potrace_bitmap_s.
    """
    if on:
        bmp.map[y*bmp.dy + x/N] |= 1 << (N - 1 - x % N)
    else:
        bmp.map[y*bmp.dy + x/N] &= ~(1 << (N - 1 - x % N))


cdef State state_from_ptr(potrace_state_s *state):
    """
    Create a State wrapping a C potrace_state_s pointer.
    """
    cdef State ret = State()
    ret.po_state = state
    return ret


cdef Path path_from_ptr(potrace_path_s *plist):
    """
    Create a Path instance containing a copy of the paths defined in *plist*.
    """
    cdef potrace_path_s *cur_path = plist
    cdef Path path = Path()    
    while cur_path != NULL:
        path.append_curve(&cur_path.curve)
        cur_path = cur_path.next
    return path


__all__ = ["Bitmap", "potracelib_version"]
