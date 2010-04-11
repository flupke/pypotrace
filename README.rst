potrace Python bindings
=======================

These bindings provide an object oriented API to the `potrace`_ library.

Example usage
-------------

The bindings work with input images represented as numpy arrays::

    import numpy as np
    import potrace

    # Make a numpy array with a rectangle in the middle
    data = np.zeros((32, 32), np.uint32)
    data[8:32-8, 8:32-8] = 1

    # Create a bitmap from the array
    bmp = potrace.Bitmap(data)

    # Trace the bitmap to a path
    path = bmp.trace()
    
    # Iterate over path curves
    for curve in path:
        print "start_point =", curve.start_point
        for segment in curve:
            print segment
            end_point_x, end_point_y = segment.end_point
            if segment.is_corner:
                c_x, c_y = segment.c
            else:
                c1_x, c1_y = segment.c1
                c2_x, c2_y = segment.c2
   
Homepage
--------

This project is hosted on github: http://github.com/flupke/pypotrace

.. _potrace: http://potrace.sourceforge.net/
