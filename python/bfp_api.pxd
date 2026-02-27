from types cimport *

# bfp_s32.h references pad_mode_e in some prototypes but doesn't include the
# header which defines it. Including vect_s32.h before bfp_s32.h ensures pad_mode_e
# is defined and compilation succeeds even if we don't use the padding APIs.
cdef extern from "xmath/vect/vect_s32.h":
  pass

cdef extern from "xmath/bfp/bfp_s32.h":
  void bfp_s32_init(bfp_s32_t* a,
                    int32_t* data,
                    const exponent_t exp,
                    const unsigned length,
                    const unsigned calc_hr)
  void bfp_s32_add(bfp_s32_t* a, const bfp_s32_t* b, const bfp_s32_t* c)
  void bfp_s32_sub(bfp_s32_t* a, const bfp_s32_t* b, const bfp_s32_t* c)
  void bfp_s32_mul(bfp_s32_t* a, const bfp_s32_t* b, const bfp_s32_t* c)
  void bfp_s32_scale(bfp_s32_t* a, const bfp_s32_t* b, const float_s32_t c)
  void bfp_s32_add_scalar(bfp_s32_t* a, const bfp_s32_t* b, const float_s32_t c)

cdef extern from "xmath/scalar/float_s32.h":
  float_s32_t float_s32_add(const float_s32_t x, const float_s32_t y)
  float_s32_t float_s32_sub(const float_s32_t x, const float_s32_t y)
  float_s32_t float_s32_mul(const float_s32_t x, const float_s32_t y)

cdef extern from "xmath/scalar/f32.h":
  float_s32_t f64_to_float_s32(const double)
  float_s32_t f32_to_float_s32(const float)
