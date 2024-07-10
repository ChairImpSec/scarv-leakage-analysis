#!/bin/sh

echo "Replace ./../../../gate/frv_masked_and_100_ns_NANG45_simple_mapped.v with the path to your synthesis results."
"$PROLEAD/release/PROLEAD" \
        -lf $PROLEAD/library.lib \
        -cf ./config.set \
        -df ./../../../gate/frv_masked_and_100_ns_NANG45_simple_mapped.v \
        -mn frv_masked_and \
        -ln NANG45 \
        -rf . \
        2>&1 | tee fixed-random.log
