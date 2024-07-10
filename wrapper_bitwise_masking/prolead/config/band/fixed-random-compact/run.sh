#!/bin/sh

$PROLEAD/release/PROLEAD \
        -lf $PROLEAD/library.lib \
        -cf ./config.set \
        -df ./../../../../gate/wrapper_bitwise_masking_100_ns_NANG45_simple_mapped.v \
        -mn wrapper_bitwise_masking \
        -ln NANG45 \
        -rf ../../../log/band/fixed-random-compact \
        2>&1 | tee ../../../log/band/fixed-random-compact/report_fixed_random.dat
