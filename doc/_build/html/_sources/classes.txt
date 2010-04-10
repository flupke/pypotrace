:mod:`potrace` -- API reference
===============================

.. module:: potrace

All objects properties are read only, unless otherwise noted. Points are
returned as tuples of *(x, y)* values.

Constants for :meth:`Bitmap.trace` *turnpolicy* parameter:

.. data:: TURNPOLICY_BLACK
.. data:: TURNPOLICY_WHITE
.. data:: TURNPOLICY_LEFT
.. data:: TURNPOLICY_RIGHT
.. data:: TURNPOLICY_MINORITY
.. data:: TURNPOLICY_MAJORITY
.. data:: TURNPOLICY_RANDOM


Bitmap
------

You start a trace by creating a :class:`Bitmap` instance, e.g.::

    from potrace import Bitmap

    # Initialize data, for example convert a PIL image to a numpy array
    # [...]

    bitmap = Bitmap(data)
    path = bitmap.trace()

.. autoclass:: Bitmap(data)
   
   .. automethod:: trace([turdsize, turnpolicy, alphamax, opticurve, opttolerance, progress_func])


Path
----

:class:`Path` instances are returned by :meth:`Bitmap.trace`:

.. autoclass:: Path

   .. attribute:: curves
      
      The list of :class:`Curve` objects composing the path.


Curve
-----

:class:`Curve` objects are the basic components of :class:`Path` objects.

.. autoclass:: Curve
   :members: start_point

   .. attribute:: segments

      The list of segment objects that compose the curve.

Segments can be either :class:`BezierSegment` or :class:`CornerSegment`
objects. Both have a :attr:`is_corner` attribute to determine their type
easily.

.. autoclass:: BezierSegment
   :members: c1, c2, end_point, is_corner


.. autoclass:: CornerSegment
   :members: c, end_point, is_corner
