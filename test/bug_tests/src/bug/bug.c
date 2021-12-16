#include <xs3_math.h>
//#include <bfp_init.h>

#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <assert.h>

#include "bfp_math.h"

#include "unity_fixture.h"

TEST_GROUP_RUNNER(bug) {
  RUN_TEST_CASE(bug, case0);
}

TEST_GROUP(bug);
TEST_SETUP(bug) { fflush(stdout); }
TEST_TEAR_DOWN(bug) {}

TEST(bug, case0){
    int32_t scratch [5] = {1, 2, 3, 4, 5};
    int32_t scratch2 [5];
    bfp_s32_t main;
    bfp_s32_t tmp;
    float_s32_t t;

    bfp_s32_init(&main, scratch, 0, 5, 0);
    bfp_s32_init(&tmp, scratch2, 0, 5, 0);

    printf("\n");

    for(int v = 0; v < 5; v++){
        t.mant = tmp.data[v];
        t.exp = tmp.exp;
        printf("%lf  |||  ", float_s32_to_double(t));
        //printf("%ld  |||  ", tmp.data[v]);
    }

    printf("\n\nInput = ");

    for(int v = 0; v < 5; v++){
        t.mant = main.data[v];
        t.exp = main.exp;
        printf("%lf  |||  ", float_s32_to_double(t));
        //printf("%ld  |||  ", main.data[v]);
    }

    printf("\n\nScale factor = ");

    t.mant = 2;
    t.exp = 0;
    printf("%lf", float_s32_to_double(t));

    bfp_s32_scale(&tmp, &main, t);
    //bfp_s32_use_exponent(&tmp, 0);

    printf("\n\n Output = ");

    for(int v = 0; v < 5; v++){
        t.mant = tmp.data[v];
        t.exp = tmp.exp;
        printf("%lf  |||  ", float_s32_to_double(t));
        //printf("%ld  |||  ", tmp.data[v]);
    }
}