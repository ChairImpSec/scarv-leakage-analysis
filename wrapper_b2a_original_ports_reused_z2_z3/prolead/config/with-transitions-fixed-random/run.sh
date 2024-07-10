#!/bin/sh

$PROLEAD/release/PROLEAD \
        -lf $PROLEAD/library.lib \
        -df ./../../../gate/wrapper_b2a_original_ports_reused_z2_z3_100_ns_NANG45_simple_mapped.v \
        -cf ./config.set \
        -mn wrapper_b2a_original_ports_reused_z2_z3 \
        -ln NANG45 \
        2>&1 | tee report-fixed-random.dat
