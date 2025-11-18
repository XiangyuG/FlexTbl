/users/xiang95/FlexTbl/iptable_kub_gen/iptable_example1.rkt:149:0
(define (impl srcPort srcIP dstPort dstIP protocol ctstate)
  (let* ((mask0 (bv #xff000000 32))
         (mask0L (bv #xff000000 32))
         (mask0R (bv #xff000000 32))
         (Const0 (bv 2130706432 32))
         (cond0 ((choose bveq) (bvand srcIP mask0) Const0))
         (Const0L (bv 2130706432 32))
         (cond0L ((choose bveq) (bvand srcIP mask0L) Const0L))
         (choice0LL 3)
         (expr0LL
          (cond
           ((= choice0LL 0) (bv 0 4))
           ((= choice0LL 1) (bv 1 4))
           (else (bv 0 4))))
         (choice0LR 1)
         (expr0LR
          (cond
           ((= choice0LR 0) (bv 0 4))
           ((= choice0LR 1) (bv 1 4))
           (else (bv 0 4))))
         (expr0L (if cond0L expr0LL expr0LR))
         (Const0R (bv 2130706432 32))
         (cond0R ((choose bveq) (bvand dstIP mask0R) Const0R))
         (choice0RL 1)
         (expr0RL
          (cond
           ((= choice0RL 0) (bv 0 4))
           ((= choice0RL 1) (bv 1 4))
           (else (bv 0 4))))
         (choice0RR 0)
         (expr0RR
          (cond
           ((= choice0RR 0) (bv 0 4))
           ((= choice0RR 1) (bv 1 4))
           (else (bv 0 4))))
         (expr0R (if cond0R expr0RL expr0RR))
         (expr0 (if cond0 expr0L expr0R)))
    expr0))
