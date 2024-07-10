# Non-Leaking version of the SCARV ALU

NOTE: To get this running, please refer to the simple example `../frv_masked_and` containing a `config.set` file and a `run.sh` file containing advice on what to change to work with these files.

This folder contains all relevant parts of a non-leaking version of the SCARV ALU.

Furthermore, the config file (`config.set`) and a script (`run.sh`) containing the required commands to invoke PROLEAD are contained in this folder.

We have used `Icarus Verilog` within all modules to verify the correctness of the Verilog code.
If you are not interested in this but want to use the Makefile, just remove the corresponding targets.

`INSECURE_XOR` in `secure_frv_masked_bitwise` is used to select one architecture of the masked xor.
To guarantee security in combination with the adder, only the architecture selected with `INSECURE_XOR = 0` is secure!


