from libc.stdint cimport int32_t

cdef extern from "xmath/types.h":
  ctypedef int exponent_t
  ctypedef unsigned int headroom_t
  ctypedef enum bfp_flags_e:
    BFP_FLAG_DYNAMIC = 1

  ctypedef struct bfp_s32_t:
    int32_t * data
    exponent_t exp
    headroom_t hr
    unsigned length
    bfp_flags_e flags

  ctypedef struct float_s32_t:
    int32_t mant
    exponent_t exp
