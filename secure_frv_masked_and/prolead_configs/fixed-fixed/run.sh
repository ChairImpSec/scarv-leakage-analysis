#!/bin/sh
$PROLEAD/release/PROLEAD \
        -lf $PROLEAD/library.lib \
        -df ./../../gate/secure_frv_masked_and_100_ns_NANG45_simple_mapped.v \
        -cf ./config.set \
        -mn secure_frv_masked_and \
        -ln NANG45 \
        2>&1 | tee Report.dat
