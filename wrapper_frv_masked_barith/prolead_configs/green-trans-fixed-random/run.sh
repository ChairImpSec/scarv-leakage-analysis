#!/bin/sh

$PROLEAD/release/PROLEAD \
        -lf $PROLEAD/library.lib \
        -df ./../../gate/wrapper_frv_masked_barith_100_ns_NANG45_simple_mapped.v \
        -cf ./config.set \
        -mn wrapper_frv_masked_barith \
        -ln NANG45 \
        2>&1 | tee report-fixed-random.txt
