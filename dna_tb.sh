#!/bin/sh
set -e

iverilog -o dna_tb.vvp -DSIM "-DVCD=\"dna_tb.fst\"" -y. -g2012 -Wall dna_tb.v
vvp -M. -N dna_tb.vvp -fst
