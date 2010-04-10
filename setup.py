#!/usr/bin/env python

from distutils.core import setup
from distutils.extension import Extension
from Cython.Distutils import build_ext


ext_modules = [
        Extension("potrace._potrace", ["potrace/_potrace.pyx"], 
            libraries=["potrace"])
    ]


setup(
    name = "potrace",
    author = "Luper Rouch",
    author_email = "luper.rouch@gmail.com",
    cmdclass = {"build_ext": build_ext},
    ext_modules = ext_modules,
)
