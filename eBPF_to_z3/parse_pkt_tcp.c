data = (void *)(long)ctx->data;
    data_end = (void *)(long)ctx->data_end;

    eth = (struct ethhdr *)data;
    if (unlikely(eth + 1 > data_end)) {
        xdp_gen_log_panic("eth + 1 > data_end");
        return XDP_ABORTED;
    }
    iph = (struct iphdr *)(eth + 1);
    if (unlikely(iph + 1 > data_end)) {
        xdp_gen_log_panic("iph + 1 > data_end");
        return XDP_ABORTED;
    }
    tcph = (struct tcphdr *)(iph + 1);
    if (unlikely(tcph + 1 > data_end)) {
        xdp_gen_log_panic("tcph + 1 > data_end");
        return XDP_ABORTED;
    }
    ts_opt = (struct tcp_timestamp_opt *)(tcph + 1);
    if (unlikely(ts_opt + 1 > data_end)) {
        xdp_gen_log_panic("ts_opt + 1 > data_end");
        return XDP_ABORTED;
    }