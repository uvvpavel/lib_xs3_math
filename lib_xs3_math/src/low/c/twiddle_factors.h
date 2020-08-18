// Copyright (c) 2020, XMOS Ltd, All rights reserved
#pragma once
#include "xs3_math.h"


/** @brief Maximum FFT length (log2) that can be performed using decimation-in-time. */
#define XS3_MAX_DIT_FFT_LOG2 10

/** @brief Convenience macro to index into the decimation-in-time FFT look-up table. 

	This will return the address at which the coefficients for the final pass of the real DIT
	FFT algorithm begin. 

	@param N	The FFT length.
*/
#define XS3_DIT_REAL_FFT_LUT(N) &xs3_dit_fft_lut[(N)-8]


/** @brief Maximum FFT length (log2) that can be performed using decimation-in-frequency. */
#define XS3_MAX_DIF_FFT_LOG2 10

/** @brief Convenience macro to index into the decimation-in-frequency FFT look-up table. 

	Use this to retrieve the correct address for the DIF FFT look-up table when performing
	an FFT (or IFFT) using the DIF algorithm. (@see xs3_fft_dif_forward).

	@param N_LOG2	log2(N) where N is the FFT length.
*/
#define XS3_DIF_FFT_LUT(N_LOG2) &xs3_dif_fft_lut[(1<<(XS3_MAX_DIF_FFT_LOG2)) - (1<<(N_LOG2))]

extern const complex_s32_t xs3_dit_fft_lut[1020]; // 8160 bytes
extern const complex_s32_t xs3_dif_fft_lut[1020]; // 8160 bytes
