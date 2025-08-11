#!/bin/bash

# Run Racket script and capture output
racket DSL_iptable.rkt > /tmp/out.txt
if [ $? -ne 0 ]; then
    echo "Error running Racket script"
    exit 1
fi

# Run Python code generation script
python3 codegen.py /tmp/out.txt > impl_fast.json
if [ $? -ne 0 ]; then
    echo "Error running codegen.py"
    exit 1
fi

# Run Python parse JSON script
python3 parse_json.py impl_fast.json > /users/xiang95/bcc/examples/networking/filter_nat.py
if [ $? -ne 0 ]; then
    echo "Error running parse_json.py"
    exit 1
fi

echo "All scripts executed successfully"
