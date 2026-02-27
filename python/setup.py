from __future__ import annotations

from pathlib import Path

from setuptools import Extension, setup

import numpy


repo_root = Path(__file__).resolve().parent.parent

lib_src = repo_root / "lib_xcore_math" / "src"

ext = Extension(
  name="xcore_math",
  sources=[
    "types.pyx",
    str(lib_src / "bfp" / "bfp_init.c"),
    str(lib_src / "scalar" / "scalar_float_s32.c"),
    str(lib_src / "scalar" / "scalar_ops.c"),
    str(lib_src / "scalar" / "scalar_f32.c"),
    str(lib_src / "bfp" / "bfp_s32.c"),
    str(lib_src / "vect" / "prepare.c"),
    str(lib_src / "vect" / "vect_s32.c"),
    str(lib_src / "arch" / "ref" / "misc.c"),
    str(lib_src / "arch" / "ref" / "vpu_scalar_ops.c"),
    str(lib_src / "arch" / "ref" / "vect_add_sub.c"),
    str(lib_src / "arch" / "ref" / "vect_headroom.c"),
    str(lib_src / "arch" / "ref" / "vect_sXX.c"),
    str(lib_src / "arch" / "ref" / "vect_mul.c"),
  ],
  include_dirs=[
    str(repo_root / "lib_xcore_math" / "api"),
    str(lib_src / "vect"),
    numpy.get_include(),
  ],
  extra_compile_args=["-ffunction-sections", "-fdata-sections", "-fvisibility=hidden"],
  extra_link_args=["-Wl,--gc-sections"],
)


def build_ext_modules():
  from Cython.Build import cythonize

  return cythonize(
    [ext],
    compiler_directives={"language_level": "3"},
  )


setup(ext_modules=build_ext_modules())