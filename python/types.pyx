# python imports 
from __future__ import annotations
import numpy as _np
# C imports
from libc.stdint cimport int32_t
cimport numpy as cnp
cimport types
cimport bfp_api


cnp.import_array()

def float_to_int32(array_float, q = 31):
  # Convert float values to Q-format int32 mantissas.
  # Do the scaling + rounding in float64 to avoid float32 precision issues
  # near int32 limits (e.g. 2**31 cannot be represented exactly in float32).
  arr = _np.asarray(array_float, dtype=_np.float64)
  scaled = _np.rint(_np.ldexp(arr, int(q)))

  imin = _np.iinfo(_np.int32).min
  imax = _np.iinfo(_np.int32).max
  if _np.any(scaled > imax) or _np.any(scaled < imin):
    raise ValueError(f"float_to_int32: value out of int32 range after scaling to {q}")

  return scaled.astype(_np.int32)

def int32_to_float(array_int32, exp = -31):
  array_float = _np.array(array_int32, dtype=_np.float64) * (2 ** exp)
  return array_float

cdef cnp.ndarray _as_s32_mant_1d(object data, types.exponent_t exp):
  """Coerce input samples into an int32 mantissa array.

  - If input is floating, interpret it as real values and quantize to mantissas
    using the provided exp: mant = round(x * 2**(-exp)).
  - If input is integer, cast to int32.
  """
  arr = _np.asarray(data, order='C')

  if arr.ndim != 1:
    raise ValueError("data must be 1-D")
  if arr.size <= 0:
    raise ValueError("data must have at least one element")

  if arr.dtype == _np.int32 and arr.flags['C_CONTIGUOUS']:
    return arr

  if arr.dtype.kind in ('f',):
    scaled = float_to_int32(arr, -exp)
    return _np.ascontiguousarray(scaled.astype(_np.int32, copy=False))

  if arr.dtype.kind in ('i', 'u', 'b'):
    return _np.ascontiguousarray(arr.astype(_np.int32, copy=False))

  raise TypeError(f"Unsupported dtype for bfp_s32 data: {arr.dtype}")


cdef class float_s32:
  cdef types.float_s32_t c_val

  def __cinit__(self, object mant_or_pair, object exp=None):
    if exp is None:
      if isinstance(mant_or_pair, float_s32):
        self.c_val = (<float_s32> mant_or_pair).c_val
        return
      elif isinstance(mant_or_pair, float) or isinstance(mant_or_pair, _np.float64):
        self.c_val = bfp_api.f64_to_float_s32(mant_or_pair)
        return
      elif isinstance(mant_or_pair, _np.float32):
        self.c_val = bfp_api.f32_to_float_s32(mant_or_pair)
        return
      try:
        self.c_val.mant = <int32_t> mant_or_pair[0]
        self.c_val.exp = <types.exponent_t> mant_or_pair[1]
      except Exception as e:
        raise TypeError("float_s32 expects (mant, exp) or mant, exp") from e
    else:
      self.c_val.mant = <int32_t> mant_or_pair
      self.c_val.exp = <types.exponent_t> exp

  @property
  def exp(self) -> int:
    return self.c_val.exp

  @property
  def mant(self) -> int:
    return self.c_val.mant
  
  def __add__(self, float_s32 another):
    cdef types.float_s32_t res = bfp_api.float_s32_add(self.c_val, another.c_val)
    return float_s32(res.mant, res.exp)

  def __sub__(self, float_s32 another):
    cdef types.float_s32_t res = bfp_api.float_s32_sub(self.c_val, another.c_val)
    return float_s32(res.mant, res.exp)

  def __neg__(self):
    return float_s32(-self.c_val.mant, self.c_val.exp)
  
  def __repr__(self) -> str:
    return f"mant={self.mant}, exp={self.exp}"


cdef class bfp_s32:
  cdef types.bfp_s32_t c_val
  cdef object _data_owner

  def add(self, bfp_s32 other):
    if self.c_val.length != other.c_val.length:
      raise ValueError("Length mismatch")

    res_arr = _np.empty(self.c_val.length, dtype=_np.int32)
    cdef bfp_s32 res = bfp_s32(res_arr, 0, 0)
    bfp_api.bfp_s32_add(&res.c_val, &self.c_val, &other.c_val)
    return res

  def add_scalar(self, float_s32 scalar):
    res_arr = _np.empty(self.c_val.length, dtype=_np.int32)
    cdef bfp_s32 res = bfp_s32(res_arr, 0, 0)
    bfp_api.bfp_s32_add_scalar(&res.c_val, &self.c_val, scalar.c_val)
    return res

  def sub(self, bfp_s32 other):
    if self.c_val.length != other.c_val.length:
      raise ValueError("Length mismatch")

    res_arr = _np.empty(self.c_val.length, dtype=_np.int32)
    cdef bfp_s32 res = bfp_s32(res_arr, 0, 0)
    bfp_api.bfp_s32_sub(&res.c_val, &self.c_val, &other.c_val)
    return res

  def sub_scalar(self, float_s32 scalar):
    cdef types.float_s32_t neg
    neg.mant = -scalar.c_val.mant
    neg.exp = scalar.c_val.exp

    res_arr = _np.empty(self.c_val.length, dtype=_np.int32)
    cdef bfp_s32 res = bfp_s32(res_arr, 0, 0)
    bfp_api.bfp_s32_add_scalar(&res.c_val, &self.c_val, neg)
    return res
  
  def mul(self, bfp_s32 other):
    if self.c_val.length != other.c_val.length:
      raise ValueError("Length mismatch")

    res_arr = _np.empty(self.c_val.length, dtype=_np.int32)
    cdef bfp_s32 res = bfp_s32(res_arr, 0, 0)
    bfp_api.bfp_s32_mul(&res.c_val, &self.c_val, &other.c_val)
    return res
  
  def scale(self, float_s32 other):
    res_arr = _np.empty(self.c_val.length, dtype=_np.int32)
    cdef bfp_s32 res = bfp_s32(res_arr, 0, 0)
    bfp_api.bfp_s32_scale(&res.c_val, &self.c_val, other.c_val)
    return res

  def to_float(self):
    return int32_to_float(self._data_owner, self.c_val.exp)

  def __cinit__(self, object data, types.exponent_t exp=-31, unsigned calc_hr=1):
    cdef cnp.ndarray arr = _as_s32_mant_1d(data, exp)
    self._data_owner = arr
    bfp_api.bfp_s32_init(&self.c_val,
                       <int32_t*> cnp.PyArray_DATA(arr),
                       exp,
                       <unsigned> cnp.PyArray_DIM(arr, 0),
                       calc_hr)

  @property
  def exp(self) -> int:
    return self.c_val.exp

  @property
  def length(self) -> int:
    return self.c_val.length

  @property
  def data(self):
    return self._data_owner

  def __add__(self, other):
    if isinstance(other, bfp_s32):
      return self.add(<bfp_s32> other)

    if isinstance(other, float_s32):
      return self.add_scalar(<float_s32> other)

    if isinstance(other, (tuple, list)) and len(other) == 2:
      return self.add_scalar(float_s32(other))

    return NotImplemented

  def __radd__(self, other):
    return self.__add__(other)

  def __sub__(self, other):
    if isinstance(other, bfp_s32):
      return self.sub(<bfp_s32> other)

    if isinstance(other, float_s32):
      return self.sub_scalar(<float_s32> other)

    if isinstance(other, (tuple, list)) and len(other) == 2:
      return self.sub_scalar(float_s32(other))

    return NotImplemented

  def __rsub__(self, other):
    return NotImplemented
  
  def __mul__(self, other):
    if isinstance(other, bfp_s32):
      return self.mul(<bfp_s32> other)

    if isinstance(other, float_s32):
      return self.scale(<float_s32> other)

    if isinstance(other, (tuple, list)) and len(other) == 2:
      return self.scale(float_s32(other))

    return NotImplemented

  def __rmul__(self, other):
    return self.__mul__(other)

  def __repr__(self) -> str:
    return f"bfp_s32(exp={self.exp}, length={self.length})"
