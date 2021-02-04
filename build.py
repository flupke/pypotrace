import subprocess
import shlex

from setuptools import Extension
from Cython.Build import cythonize

import numpy as np


def pkg_config(pkg_name, command):
    return subprocess.check_output(["pkg-config", command, pkg_name]).decode(
        "utf8"
    )


def build(setup_kwargs):
    """Needed for the poetry building interface."""

    extra_compile_args = pkg_config("libagg", '--cflags')
    extra_link_args = pkg_config("libagg", '--libs')
    extra_compile_args = shlex.split(extra_compile_args)
    extra_link_args = shlex.split(extra_link_args)

    print(extra_compile_args)
    print(extra_link_args)

    extensions = [
        Extension(
            "potrace._potrace",
            sources=["potrace/_potrace.pyx"],
            include_dirs=[np.get_include()],
            libraries=["potrace"],
        ),
        Extension(
            "potrace.bezier",
            sources=["potrace/bezier.pyx"],
            include_dirs=[np.get_include()],
            language="c++",
            extra_compile_args=extra_compile_args,
            extra_link_args=extra_link_args,
        ),
        Extension(
            "potrace.agg.curves",
            sources=["potrace/agg/curves.pyx"],
            language="c++",
            extra_compile_args=extra_compile_args,
            extra_link_args=extra_link_args,
        ),
    ]

    extensions = cythonize(extensions)

    setup_kwargs.update(
        {
            "ext_modules": extensions,
            "include_dirs": [np.get_include()],
        }
    )
