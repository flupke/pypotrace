Tutorial
========

.. currentmodule:: potrace

Here is a simple example using pypotrace::

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


The main class is :class:`Bitmap`. You pass its constructor a 2D numpy array,
and you call its :meth:`trace() <Bitmap.trace>` method to convert it to a
:class:`Path` object.
