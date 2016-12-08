#!/usr/bin/env python

import os
import subprocess
from setuptools import setup
from distutils.extension import Extension

# Use Cython version of build_ext if the CYTHONIZE environment variable is set
CYTHONIZE = 'CYTHONIZE' in os.environ
if CYTHONIZE:
    from Cython.Distutils import build_ext
else:
    from setuptools.command.build_ext import build_ext

# Get numpy include dirs
try:
    import numpy
    include_dirs = [numpy.get_include()]
except ImportError:
    include_dirs = []


def get_flags(flags, prefix):
    return [flag[2:] for flag in flags if flag.startswith(prefix)]


def create_ext_obj(name, sources, cython=False, pkg_config_libs=None, **kwargs):
    '''
    Create an :class:`~distutils.extension.Extension` object for module *name*,
    built from *sources*.

    *sources* strings are interpolated with the ``{ext}`` named variable.
    ``ext`` is determined automatically depending on the *cython* argument and
    the value of the *language* keyword argument. This way if Cython is
    present, Cython source files are compiled to C (typically on a developer
    machine), and if it's absent (e.g. on a deployment machine) the existing C
    files are compiled.

    Any other extra keyword arguments are passed as-is to
    :class:`~distutils.extension.Extension` constructor.
    '''
    if pkg_config_libs is not None:
        args = ['pkg-config', '--libs', '--cflags']
        args.extend(pkg_config_libs)
        pkg_config_output = subprocess.check_output(args)
        flags = pkg_config_output.split()
        for key, flag in (
                ('include_dirs', '-I'),
                ('library_dirs', '-L'),
                ('libraries', '-l')):
            pkg_config_flags = get_flags(flags, flag)
            kwargs_value = kwargs.get(key, [])
            kwargs_value += pkg_config_flags
            kwargs[key] = kwargs_value
    if cython:
        ext = 'pyx'
    elif kwargs.get('language') == 'c++':
        ext = 'cpp'
    else:
        ext = 'c'
    sources = [s.format(ext=ext) for s in sources]
    return Extension(name=name, sources=sources, **kwargs)


ext_modules = [
    create_ext_obj("potrace._potrace", ["potrace/_potrace.{ext}"],
        libraries=["potrace"], include_dirs=include_dirs, cython=CYTHONIZE),
    create_ext_obj("potrace.bezier", ["potrace/bezier.{ext}"],
        pkg_config_libs=['libagg'], language="c++", include_dirs=include_dirs,
        cython=CYTHONIZE),
    create_ext_obj("potrace.agg.curves", ["potrace/agg/curves.{ext}"],
        pkg_config_libs=['libagg'], language="c++", include_dirs=include_dirs,
        cython=CYTHONIZE),
]


setup(
    name = "pypotrace",
    author = "Luper Rouch",
    author_email = "luper.rouch@gmail.com",
    url = "http://github.com/flupke/pypotrace",
    description = "potrace Python bindings",
    long_description = open("README.rst").read(),
    version = "0.1.3",
    classifiers = [
        "Development Status :: 4 - Beta",
        "Environment :: Console",
        "Intended Audience :: Developers",
        "License :: OSI Approved :: GNU General Public License (GPL)",
        "Natural Language :: English",
        "Operating System :: OS Independent",
        "Programming Language :: Cython",
        "Programming Language :: Python",
        "Topic :: Software Development :: Libraries :: Python Modules",
        "Topic :: Multimedia :: Graphics :: Graphics Conversion",
    ],

    packages = ["potrace", "potrace.agg"],
    ext_modules = ext_modules,

    cmdclass = {"build_ext": build_ext},
)
