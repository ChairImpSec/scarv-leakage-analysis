#!/bin/sh

$PROLEAD/release/PROLEAD \
        -lf $PROLEAD/library.lib \
        -df ./../../../gate/wrapper_frv_masked_shfrot_100_ns_NANG45_simple_mapped.v \
        -cf ./config.set \
        -mn wrapper_frv_masked_shfrot \
        -ln NANG45 \
        2>&1 | tee Report-fixed-fixed.dat
