#!/bin/sh
set -e

iverilog -o dna_apb_tb.vvp -DSIM "-DVCD=\"dna_apb_tb.fst\"" -y. -g2012 -Wall dna_apb_tb.v
vvp -M. -N dna_apb_tb.vvp -fst
