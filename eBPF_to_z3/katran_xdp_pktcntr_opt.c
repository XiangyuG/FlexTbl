```c
/* Copyright (C) 2018-present, Facebook, Inc. */

#include <linux/if.h>
#include <linux/if_ether.h>
#include <linux/if_tunnel.h>
#include <linux/in.h>
#include <linux/ip.h>
#include <linux/ipv6.h>
#include <linux/pkt_cls.h>

#include "bpf.h"
#include "bpf_helpers.h"

#define MERGED_ARRAY_SIZE 512

struct merged_val {
    __u32 flag;
    __u64 counter;
};

struct {
    __uint(type, BPF_MAP_TYPE_PERCPU_ARRAY);
    __type(key, __u32);
    __type(value, struct merged_val);
    __uint(max_entries, MERGED_ARRAY_SIZE);
} merged_array SEC(".maps");

SEC("xdp")
int pktcntr(struct xdp_md* ctx)
{
    __u32 pos = 0;

    struct merged_val* val;

    val = bpf_map_lookup_elem(&merged_array, &pos);

    if (!val) {
        return XDP_PASS;
    }

    if (val->flag == 0) {
        return XDP_PASS;
    }

    val->counter += 1;

    return XDP_PASS;
}

char _license[] SEC("license") = "GPL";
```
