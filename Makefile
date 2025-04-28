IVERILOG=iverilog
VVP=vvp

TBs = $(wildcard *_tb.v)

all: $(TBs:%.v=%.fst)

clean:
	rm -f *.d *.vvp *.fst

%.fst: %.vvp
	$(VVP) -M. -N "$<" -fst

%.vvp: %.v
	$(IVERILOG) -o "$@" -Mall="$@.d1" "-DVCD=\"$*.fst\""  -y. -g2012 -Wall "$<"
	echo -n "$@ : Makefile " > "$@.d"
	cat "$@.d1" | sort -u | xargs echo >> "$@.d"
	rm "$@.d1"

-include $(wildcard *.d)
