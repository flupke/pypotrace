cimport numpy as np


cdef np.ndarray bezier(np.ndarray p, int steps=?)
cdef np.ndarray adaptive_bezier(np.ndarray p)
