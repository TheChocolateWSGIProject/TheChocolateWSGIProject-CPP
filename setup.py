#!/usr/bin/env python
from setuptools import setup, Extension
from Cython.Build import cythonize

setup(
    name = "chocolate-cpp",
    version = "0.0.4",
    author = "BK Shrinandhan",
    author_email = "python.access.server@gmail.com",
    description = "An Optimized version of Chocolate",
    ext_modules=cythonize([
        Extension("chocolate_cpp.server",["chocolate_cpp/_server.pyx"]),
        Extension("chocolate_cpp.middleware",["chocolate_cpp/_middleware.pyx"])
    ])
)
