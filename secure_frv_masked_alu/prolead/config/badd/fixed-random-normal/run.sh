#!/bin/sh

$PROLEAD/release/PROLEAD \
        -lf $PROLEAD/library.lib \
        -cf ./config.set \
        -df ./../../../../gate/secure_frv_masked_alu_100_ns_NANG45_simple_mapped.v \
        -mn secure_frv_masked_alu \
        -ln NANG45 \
        -rf ../../../log/badd/fixed-random-normal \
        2>&1 | tee ../../../log/badd/fixed-random-normal/report_fixed_random.dat
