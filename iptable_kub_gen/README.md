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

## 🧪 Usage

Run any `.rkt` file with:

```bash
racket <filename>.rkt
