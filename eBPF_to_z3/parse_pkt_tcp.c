#include <linux/bpf.h>
#include <linux/if_ether.h>
#include <linux/ip.h>
#include <linux/tcp.h>

#include <bpf/bpf_helpers.h>
#include <bpf/bpf_endian.h>

char LICENSE[] SEC("license") = "GPL";

/* ------------------------------------------------ */
/* Helper macro                                     */
/* ------------------------------------------------ */

#ifndef unlikely
#define unlikely(x) __builtin_expect(!!(x), 0)
#endif

/* ------------------------------------------------ */
/* Example TCP timestamp option                     */
/* ------------------------------------------------ */

struct tcp_timestamp_opt {
    __u8  kind;
    __u8  len;
    __u32 tsval;
    __u32 tsecr;
};

/* ------------------------------------------------ */
/* XDP program                                      */
/* ------------------------------------------------ */

SEC("xdp")
int xdp_incremental_parser(struct xdp_md *ctx)
{
    void *data;
    void *data_end;

    struct ethhdr *eth;
    struct iphdr *iph;
    struct tcphdr *tcph;
    struct tcp_timestamp_opt *ts_opt;

    /* -------------------------------------------- */
    /* Initialize packet pointers                   */
    /* -------------------------------------------- */

    data = (void *)(long)ctx->data;
    data_end = (void *)(long)ctx->data_end;

    /* -------------------------------------------- */
    /* Ethernet header                              */
    /* -------------------------------------------- */

    eth = (struct ethhdr *)data;

    if (unlikely((void *)(eth + 1) > data_end)) {
        return XDP_ABORTED;
    }

    /* -------------------------------------------- */
    /* IPv4 header                                  */
    /* -------------------------------------------- */

    iph = (struct iphdr *)(eth + 1);

    if (unlikely((void *)(iph + 1) > data_end)) {
        return XDP_ABORTED;
    }

    /* -------------------------------------------- */
    /* TCP header                                   */
    /* -------------------------------------------- */

    tcph = (struct tcphdr *)(iph + 1);

    if (unlikely((void *)(tcph + 1) > data_end)) {
        return XDP_ABORTED;
    }

    /* -------------------------------------------- */
    /* TCP timestamp option                         */
    /* -------------------------------------------- */

    ts_opt = (struct tcp_timestamp_opt *)(tcph + 1);

    if (unlikely((void *)(ts_opt + 1) > data_end)) {
        return XDP_ABORTED;
    }

    return XDP_PASS;
}