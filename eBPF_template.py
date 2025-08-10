#!/usr/bin/env python3
import bcc
from bcc import BPF
import socket
import ctypes
import time

# Define the eBPF C code
bpf_code = r"""
#include <uapi/linux/bpf.h>
#include <linux/if_ether.h>
#include <linux/ip.h>
#include <linux/if_packet.h>
#include <uapi/linux/tcp.h>
#include <uapi/linux/udp.h>
#include <linux/in.h>

// Define a struct for the key (source IP + port)
struct ip_port_key {
    u32 ip;
    u16 port;
};

BPF_HASH(decision, struct ip_port_key, u32);  // time stamp

int filter_nat(struct xdp_md *ctx) {
    // Access the Ethernet header
    void *data = (void *)(long)ctx->data;
    void *data_end = (void *)(long)ctx->data_end;
    struct ethhdr *eth = data;

    // Check if the Ethernet header is valid and that it's an IPv4 packet
    if ((void *)(eth + 1) > data_end)
        return XDP_PASS;  // If the packet is too short to have an Ethernet header, pass

    if (eth->h_proto == bpf_htons(ETH_P_IP)) {  // If it's an IPv4 packet
        // Access the IP header
        struct iphdr *ip = (struct iphdr *)(eth + 1);

        // Check that the IP header is valid and the packet is large enough
        if ((void *)(ip + 1) > data_end)
            return XDP_PASS;  // If the packet is too short to have an IP header, pass

        // Extract the source IP address (htonl converts to readable format)
        u32 srcip = bpf_ntohl(ip->saddr);
        u32 dstip = bpf_ntohl(ip->daddr);
        u32 proto = ip->protocol;
        u16 sport = 0;
        u16 dport = 0;

        struct tcphdr *tcp = 0;
        struct udphdr *udp = 0;

        if (proto == IPPROTO_TCP) {
            tcp = (struct tcphdr *)((void *)ip + (ip->ihl * 4));
            if ((void *)(tcp + 1) > data_end)
                return XDP_PASS;
            sport = bpf_ntohs(tcp->source);
            dport = bpf_ntohs(tcp->dest);
        } else if (proto == IPPROTO_UDP) {
            udp = (struct udphdr *)((void *)ip + (ip->ihl * 4));
            if ((void *)(udp + 1) > data_end)
                return XDP_PASS;
            sport = bpf_ntohs(udp->source);
            dport = bpf_ntohs(udp->dest);
        }

        {{MY PROGRAM}}

    }

    return XDP_PASS;  // Allow other packets to pass.
}
"""

# Initialize BPF object
b = BPF(text=bpf_code)

# Attach the eBPF program to the network interface (e.g., eth0)
interface = "dummy0"  # Modify with the interface you want to attach the program to
b.attach_xdp(interface, b.load_func("filter_nat", bcc.BPF.XDP))

print(f"eBPF program attached to {interface}.")

# Start tracing (only prints bpf_printk if you add it in C)
try:
    while True:
        b.trace_print()
except KeyboardInterrupt:
    print("Detaching eBPF program")
    b.remove_xdp(interface)
