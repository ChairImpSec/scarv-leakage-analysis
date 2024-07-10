#!/bin/sh

"$PROLEAD/release/PROLEAD" \
        -lf $PROLEAD/library.lib \
        -cf ./config.set \
        -df ./../../../gate/secure_frv_masked_and_reduced_randomness_100_ns_NANG45_simple_mapped.v \
        -mn secure_frv_masked_and_reduced_randomness \
        -ln NANG45 \
        -rf . \
        2>&1 | tee fixed-random.log
