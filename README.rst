potrace Python bindings
=======================

These bindings provide an object oriented API to the `potrace`_ library.

The full API documentation is on `<https://pythonhosted.org/pypotrace/>`_.


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

Installation
------------

Ubuntu
~~~~~~

Install system dependencies::

    $ sudo apt-get install build-essential python-dev libagg-dev libpotrace-dev pkg-config

Install pypotrace::

    $ git clone https://github.com/flupke/pypotrace.git
    $ cd pypotrace
    $ pip install numpy
    $ pip install .

CentOS/RedHat
~~~~~~~~~~~~~

Install system dependencies::

    $ sudo yum -y groupinstall "Development Tools"
    $ sudo yum -y install agg-devel potrace-devel python-devel

Install pypotrace::

    $ git clone https://github.com/flupke/pypotrace.git
    $ cd pypotrace
    $ pip install numpy
    $ pip install .

OSX
~~~

Install system dependencies::

    $ brew install libagg pkg-config potrace

Install pypotrace::

    $ git clone https://github.com/flupke/pypotrace.git
    $ cd pypotrace
    $ pip install numpy
    $ pip install .

Windows
~~~~~~~

*Thanks to* `klonuo <https://github.com/klonuo>`_ *for the instructions*

Here are instruction how to make this package work on Windows, by using MinGW
system. Probably it can be done with Visual Studio, but I lack skills to make
such magic.

So assuming user has MinGW available, additional two packages are needed:

1. potrace source: http://potrace.sourceforge.net/#downloading
2. agg source: http://www.antigrain.com/download/index.html

I extracted both packages in my ``C:\src`` folder. Both are easy to build by
executing ``./configure; make`` and ``./autogen.sh; make`` respectively, on
MSYS prompt.

After that, we need some variables to build pypotrace successfully:

First, includes paths:

* "numpy/arrayobject.h": ``C:/Python27/Lib/site-packages/numpy/core/include``
* potrace headers: ``C:/src/potrace-1.11/src``
* agg headers: ``C:/src/agg-2.5``

there is a little catch for agg includes, as paths referenced in cpp sources
point to ``agg2/*.h`` while in downloaded agg package we don't have ``agg2``
folder. For me it was easiest to rename ``C:/src/agg-2.5/include`` to
``C:/src/agg-2.5/agg2`` and use ``C:/src/agg-2.5`` as agg include folder.

Next, libdirs for libraries we build above:

* potrace: ``C:/src/potrace-1.11/src/.libs``
* agg: ``C:/src/agg-2.5/src``

and we can make pypotrace build command, and execute it::

    python setup.py build_ext -IC:/Python27/Lib/site-packages/numpy/core/include;C:/src/potrace-1.11/src;C:/src/agg-2.5 -LC:/src/potrace-1.11/src/.libs;C:/src/agg-2.5/src

Finally install the package::

    C:\src\git\pypotrace>python setup.py install
    running install
    running build
    running build_py
    copying potrace\__init__.py -> build\lib.win32-2.7\potrace
    copying potrace\agg\__init__.py -> build\lib.win32-2.7\potrace\agg
    running build_ext
    skipping 'potrace\_potrace.c' Cython extension (up-to-date)
    skipping 'potrace\bezier.cpp' Cython extension (up-to-date)
    skipping 'potrace/agg\curves.cpp' Cython extension (up-to-date)
    running install_lib
    creating C:\Python27\Lib\site-packages\potrace
    creating C:\Python27\Lib\site-packages\potrace\agg
    copying build\lib.win32-2.7\potrace\agg\curves.pyd -> C:\Python27\Lib\site-packages\potrace\agg
    copying build\lib.win32-2.7\potrace\agg\__init__.py -> C:\Python27\Lib\site-packages\potrace\agg
    copying build\lib.win32-2.7\potrace\bezier.pyd -> C:\Python27\Lib\site-packages\potrace
    copying build\lib.win32-2.7\potrace\_potrace.pyd -> C:\Python27\Lib\site-packages\potrace
    copying build\lib.win32-2.7\potrace\__init__.py -> C:\Python27\Lib\site-packages\potrace
    byte-compiling C:\Python27\Lib\site-packages\potrace\agg\__init__.py to __init__.pyc
    byte-compiling C:\Python27\Lib\site-packages\potrace\__init__.py to __init__.pyc
    running install_egg_info
    Writing C:\Python27\Lib\site-packages\pypotrace-0.1-py2.7.egg-info

Running tests
-------------

You can check everything is working correctly by running the tests::

    $ pip install '.[dev]'
    $ nosetests -v

Documentation
-------------

The documentation is hosted here: http://packages.python.org/pypotrace

A copy is also included in the ``doc/_build/html`` directory of the source
distribution.

Homepage
--------

This project is hosted on github: http://github.com/flupke/pypotrace

.. _potrace: http://potrace.sourceforge.net/
