#include <linux/bpf.h>
#include <bpf/bpf_helpers.h>
#include <linux/if_ether.h>
#include <linux/ip.h>
#include <linux/tcp.h>

char LICENSE[] SEC("license") = "GPL";

/* ------------------------------------------------ */
/* Example TCP timestamp option structure           */
/* ------------------------------------------------ */

struct tcp_timestamp_opt {
    __u8 kind;
    __u8 len;
    __u32 tsval;
    __u32 tsecr;
};

/* ------------------------------------------------ */
/* XDP program                                      */
/* ------------------------------------------------ */

SEC("xdp")
int xdp_parser(struct xdp_md *ctx)
{
    void *data;
    void *data_end;

    struct ethhdr *eth;
    struct iphdr *iph;
    struct tcphdr *tcph;
    struct tcp_timestamp_opt *ts_opt;

    data = (void *)(long)ctx->data;
    data_end = (void *)(long)ctx->data_end;

    /*
     * Final required packet size:
     *
     * ethhdr
     * + iphdr
     * + tcphdr
     * + tcp_timestamp_opt
     */

    void *required_end =
        data
        + sizeof(struct ethhdr)
        + sizeof(struct iphdr)
        + sizeof(struct tcphdr)
        + sizeof(struct tcp_timestamp_opt);

    if (required_end > data_end) {
        bpf_printk("packet too short\n");
        return XDP_ABORTED;
    }

    /* Safe to assign all headers now */

    eth = (struct ethhdr *)data;

    iph = (struct iphdr *)(eth + 1);

    tcph = (struct tcphdr *)(iph + 1);

    ts_opt = (struct tcp_timestamp_opt *)(tcph + 1);

    return XDP_PASS;
}