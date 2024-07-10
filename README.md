
# SCARV Leakage Analysis

This repository contains modified and original files taken from [scarv/scarv-cpu](https://github.com/scarv/scarv-cpu/tree/scarv/xcrypto/masking-ise), which were used to analyze the leakage behavior of the masking-ise of the scarv-cpu.
The analysis can be found in the paper TODO:LinkToPaper.

# Where to start?
If you're interested in the Verilog code for our version of the SCARE core, start with `./secure_frv_masked_alu/src`.
This folder contains all the files relevant to building our non-leaking version of the SCARV core.

For our experiments using [PROLEAD](https://github.com/ChairImpSec/PROLEAD), begin with the files in `./frv_masked_and/`.
This folder includes the first and simplest experiment from our analysis.
Running [PROLEAD](https://github.com/ChairImpSec/PROLEAD) on this small design is quick and can be done on nearly any computer.

Other folders primarily provide different wrappers, allowing [PROLEAD](https://github.com/ChairImpSec/PROLEAD) to investigate various subsets of the entire ALU.

Please note that except for `./frv_masked_and`, all other folders contain Verilog files, leading to designs in which [PROLEAD](https://github.com/ChairImpSec/PROLEAD) detects no leakage.
These folders include versions of the designs after our fixes are applied.

Furthermore, we have tried to keep the impact of our changes on the source code as minimal as possible.
Without this constraint, it might be possible to make the code more readable.
