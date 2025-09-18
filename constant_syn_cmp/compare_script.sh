#!/bin/bash

OUTFILE="timing_results.txt"
> "$OUTFILE"

START=9
END=10

for i in $(seq $START $END); do
    for variant in "" "_vanilla"; do
        script="constant_syn${i}${variant}.rkt"
        if [[ -f "$script" ]]; then
            echo "Running $script..." | tee -a "$OUTFILE"
            { time racket "$script" ; } 2>>"$OUTFILE"
            echo "---------------------------------" >> "$OUTFILE"
        else
            echo "Skipping $script (not found)" | tee -a "$OUTFILE"
        fi
    done
done
