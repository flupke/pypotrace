cimport numpy as np
cimport stdlib
from python_string cimport PyString_FromString

import numpy as np


# Number of pixels in a word
cdef int N = sizeof(potrace_word) * 8

# Constants
TURNPOLICY_BLACK = POTRACE_TURNPOLICY_BLACK
TURNPOLICY_WHITE = POTRACE_TURNPOLICY_WHITE
TURNPOLICY_LEFT = POTRACE_TURNPOLICY_LEFT
TURNPOLICY_RIGHT = POTRACE_TURNPOLICY_RIGHT
TURNPOLICY_MINORITY = POTRACE_TURNPOLICY_MINORITY
TURNPOLICY_MAJORITY = POTRACE_TURNPOLICY_MAJORITY
TURNPOLICY_RANDOM = POTRACE_TURNPOLICY_RANDOM


class PotraceError(Exception): pass


cdef class Bitmap:
    """
    Create a Bitmap instance.

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
        Trace the bitmap and wrap the result in a :class:`Path` instance.

        The *turdsize* parameter can be used to "despeckle" the bitmap to be
        traced, by removing all curves whose enclosed area is below the given
        threshold. The current default for the *turdsize* parameter is 2; its
        useful range is from 0 to infinity.

        The *turnpolicy* parameter determines how to resolve ambiguities during
        decomposition of bitmaps into paths. The possible choices for the
        *turnpolicy* parameter are:
        
        * :const:`TURNPOLICY_BLACK`: prefers to connect black
          (foreground) components.

        * :const:`TURNPOLICY_WHITE`: prefers to connect white
          (background) components.
        
        * :const:`TURNPOLICY_LEFT`: always take a left turn.

        * :const:`TURNPOLICY_RIGHT`: always take a right turn.

        * :const:`TURNPOLICY_MINORITY`: prefers to connect the color
          (black or white) that occurs least frequently in a local neighborhood
          of the current position.

        * :const:`TURNPOLICY_MAJORITY`: prefers to connect the color 
          (black or white) that occurs most frequently in a local neighborhood
          of the current position.

        * :const:`TURNPOLICY_RANDOM`: choose randomly.
        
        The current default policy is :const:`TURNPOLICY_MINORITY`, which tends
        to keep visual lines connected.

        The *alphamax* parameter is a threshold for the detection of corners.
        It controls the smoothness of the traced curve. The current default is
        1.0; useful range of this parameter is from 0.0 (polygon) to 1.3333
        (no corners).

        The *opticurve* parameter is a boolean flag that controls whether
        Potrace will attempt to "simplify" the final curve by reducing the
        number of Bezier curve segments.  Opticurve=1 turns on optimization,
        and *opticurve=0* turns it off. The current default is on.

        The *opttolerance* parameter defines the amount of error allowed in
        this simplification. The current default is 0.2. Larger values tend to
        decrease the number of segments, at the expense of less accuracy. The
        useful range is from 0 to infinity, although in practice one would
        hardly choose values greater than 1 or so. For most purposes, the
        default value is a good tradeoff between space and accuracy.
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
            int opticurve=1, double opttolerance=0.2, *args, **kwargs):
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
    """
    Represents a Bezier segment in a :class:`Curve` object.
    """

    cdef public tuple c1, c2, end_point
    cdef public bool is_corner

    def __init__(self, c1, c2, end_point):
        self.c1 = c1
        self.c2 = c2
        self.end_point = end_point
        self.is_corner = False

    def __repr__(self):
        return "BezierSegment(c1=%s, c2=%s, end_point=%s)" % (self.c1,
                self.c2, self.end_point)


cdef class CornerSegment:
    """
    Represents a corner segment in a :class:`Curve` object.
    """

    cdef public tuple c, end_point
    cdef public bool is_corner

    def __init__(self, c, end_point):
        self.c = c
        self.end_point = end_point
        self.is_corner = True

    def __repr__(self):
        return "CornerSegment(c=%s, end_point=%s)" % (self.c, self.end_point)


cdef class Curve:
    """
    Curve objects represent closed, non intersecting curves.

    Curves are made of a list of :class:`BezierSegment` and
    :class:`CornerSegment` objects connected to each other.
    """

    cdef public list segments

    def __init__(self):
        self.segments = []

    property start_point:
        """
        The curve starting point.
        """
        def __get__(self):
            return self.segments[-1].end_point

    def __iter__(self):
        return iter(self.segments)

    cdef append_bezier(self, potrace_dpoint_s *c1, potrace_dpoint_s *c2,
            potrace_dpoint_s *end_point):
        self.segments.append(BezierSegment((c1.x, c1.y), (c2.x, c2.y),
            (end_point.x, end_point.y)))

    cdef append_corner(self, potrace_dpoint_s *c, potrace_dpoint_s *end_point):
        self.segments.append(CornerSegment((c.x, c.y), (end_point.x,
            end_point.y)))


cdef class Path:
    """
    Path objects store a list of :class:`Curve` objects.
    """

    cdef public list curves

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


__all__ = ["TURNPOLICY_BLACK", "TURNPOLICY_WHITE", "TURNPOLICY_LEFT",
    "TURNPOLICY_RIGHT", "TURNPOLICY_MINORITY", "TURNPOLICY_MAJORITY",
    "TURNPOLICY_RANDOM", "Bitmap", "Path", "Curve", "BezierSegment",
    "CornerSegment", "potracelib_version"]
