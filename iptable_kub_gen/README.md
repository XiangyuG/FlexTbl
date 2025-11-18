# FlexTbl Rosette Experiments

This folder contains Rosette-based experiments for representing iptables logic and verifying functional equivalence of synthesized programs.

## 📄 Files Overview

### **1. `iptable_kub_gen.rkt`**
This file defines the **specification of iptables behavior** in Rosette using a **nested if–then–else** structure.  
It models how iptables rules are evaluated sequentially, including:

- Rule condition evaluation  
- Chain jumping behavior  
- State updates (e.g., ctstate)  
- Returning decisions in a structured list format  

---

### **2. `compare_list.rkt`**
This file provides utility functions to **compare two lists of bitvector outputs**.

It includes:

- A symbolic-safe list equality function  
- Elementwise bitvector comparison using `bveq`  
- A fold-based equivalence aggregator  

---

### **3. `gen_impl.py`**
This file provides functions to **generate implementation (nested If-then-else statement) for eBPF**.

### **4. All python files in the parser folder**
This file provides functions to **parse the output of synthesizer and generate eBPF programs**.


## 🧪 Usage

Run any `.rkt` file with:

```bash
racket <filename>.rkt
```
```bash
python3 gen_impl.py <depth>
```
```bash
cd parser
python3 parse_impl.py impl.rkt 
```
