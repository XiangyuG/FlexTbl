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

if (unlikely(required_end > data_end)) {
    xdp_gen_log_panic("packet too short");
    return XDP_ABORTED;
}

/* Safe to assign all headers now */

eth = (struct ethhdr *)data;

iph = (struct iphdr *)(eth + 1);

tcph = (struct tcphdr *)(iph + 1);

ts_opt = (struct tcp_timestamp_opt *)(tcph + 1);
