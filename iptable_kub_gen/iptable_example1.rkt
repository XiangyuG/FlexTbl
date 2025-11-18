;;; Spec iptable program

;;; Chain INPUT (policy ACCEPT 0 packets, 0 bytes)
;;; num   pkts bytes target     prot opt in     out     source               destination         
;;; 1    1629K  137M KUBE-PROXY-FIREWALL  all  --  *      *       0.0.0.0/0            0.0.0.0/0            ctstate NEW /* kubernetes load balancer firewall */
;;; 2      76M   12G KUBE-NODEPORTS  all  --  *      *       0.0.0.0/0            0.0.0.0/0            /* kubernetes health check service ports */
;;; 3    1629K  137M KUBE-EXTERNAL-SERVICES  all  --  *      *       0.0.0.0/0            0.0.0.0/0            ctstate NEW /* kubernetes externally-visible service portals */
;;; 4      76M   12G KUBE-FIREWALL  all  --  *      *       0.0.0.0/0            0.0.0.0/0           

;;; Chain KUBE-EXTERNAL-SERVICES (2 references)
;;; num   pkts bytes target     prot opt in     out     source               destination         

;;; Chain KUBE-FIREWALL (2 references)
;;; num   pkts bytes target     prot opt in     out     source               destination         
;;; 1        0     0 DROP       all  --  *      *      !127.0.0.0/8          127.0.0.0/8          /* block incoming localnet connections */


;;; Chain KUBE-NODEPORTS (1 references)
;;; num   pkts bytes target     prot opt in     out     source               destination         

;;; Chain KUBE-PROXY-FIREWALL (3 references)
;;; num   pkts bytes target     prot opt in     out     source               destination         

#lang rosette/safe

(require rosette/lib/synthax)
(require rosette/base/base)
(require rosette/solver/smt/z3)

;; --- symbolic inputs ---
(define-symbolic srcPort_sym (bitvector 16))
(define-symbolic srcIP_sym (bitvector 32))
(define-symbolic dstPort_sym (bitvector 16))
(define-symbolic dstIP_sym (bitvector 32))
(define-symbolic protocol_sym (bitvector 8))
(define-symbolic ctstate_sym (bitvector 4))


(define (list-bv-equal? l1 l2)
  (foldl (lambda (a acc) (and a acc))
         #t
         (map bveq l1 l2)))

(define NEW (bv 0 4))
(define RELATED (bv 1 4))
(define ESTABLISHED (bv 2 4))
(define INVALID (bv 3 4))
(define DNAT (bv 4 4))
(define (input srcPort srcIP dstPort dstIP protocol ctstate)
  (cond
  [(and #t #t #t (bveq ctstate NEW)) (let ([decision (kube_proxy_firewall srcPort srcIP dstPort dstIP protocol ctstate)])
      (if (not (bveq decision (bv 5 4)))
            decision
            (cond
[(and #t #t #t #t) (let ([decision (kube_nodeports srcPort srcIP dstPort dstIP protocol ctstate)])
      (if (not (bveq decision (bv 5 4)))
            decision
            (cond
[(and #t #t #t (bveq ctstate NEW)) (let ([decision (kube_external_services srcPort srcIP dstPort dstIP protocol ctstate)])
      (if (not (bveq decision (bv 5 4)))
            decision
            (cond
[(and #t #t #t #t) (let ([decision (kube_firewall srcPort srcIP dstPort dstIP protocol ctstate)])
      (if (not (bveq decision (bv 5 4)))
            decision
            (bv 0 4)))]
[else (bv 0 4)])))]
[(and #t #t #t #t) (let ([decision (kube_firewall srcPort srcIP dstPort dstIP protocol ctstate)])
      (if (not (bveq decision (bv 5 4)))
            decision
            (bv 0 4)))]
[else (bv 0 4)])))]
[(and #t #t #t (bveq ctstate NEW)) (let ([decision (kube_external_services srcPort srcIP dstPort dstIP protocol ctstate)])
      (if (not (bveq decision (bv 5 4)))
            decision
            (cond
[(and #t #t #t #t) (let ([decision (kube_firewall srcPort srcIP dstPort dstIP protocol ctstate)])
      (if (not (bveq decision (bv 5 4)))
            decision
            (bv 0 4)))]
[else (bv 0 4)])))]
[(and #t #t #t #t) (let ([decision (kube_firewall srcPort srcIP dstPort dstIP protocol ctstate)])
      (if (not (bveq decision (bv 5 4)))
            decision
            (bv 0 4)))]
[else (bv 0 4)])))]

  [(and #t #t #t #t) (let ([decision (kube_nodeports srcPort srcIP dstPort dstIP protocol ctstate)])
      (if (not (bveq decision (bv 5 4)))
            decision
            (cond
[(and #t #t #t (bveq ctstate NEW)) (let ([decision (kube_external_services srcPort srcIP dstPort dstIP protocol ctstate)])
      (if (not (bveq decision (bv 5 4)))
            decision
            (cond
[(and #t #t #t #t) (let ([decision (kube_firewall srcPort srcIP dstPort dstIP protocol ctstate)])
      (if (not (bveq decision (bv 5 4)))
            decision
            (bv 0 4)))]
[else (bv 0 4)])))]
[(and #t #t #t #t) (let ([decision (kube_firewall srcPort srcIP dstPort dstIP protocol ctstate)])
      (if (not (bveq decision (bv 5 4)))
            decision
            (bv 0 4)))]
[else (bv 0 4)])))]

  [(and #t #t #t (bveq ctstate NEW)) (let ([decision (kube_external_services srcPort srcIP dstPort dstIP protocol ctstate)])
      (if (not (bveq decision (bv 5 4)))
            decision
            (cond
[(and #t #t #t #t) (let ([decision (kube_firewall srcPort srcIP dstPort dstIP protocol ctstate)])
      (if (not (bveq decision (bv 5 4)))
            decision
            (bv 0 4)))]
[else (bv 0 4)])))]

  [(and #t #t #t #t) (let ([decision (kube_firewall srcPort srcIP dstPort dstIP protocol ctstate)])
      (if (not (bveq decision (bv 5 4)))
            decision
            (bv 0 4)))]

  [else (bv 0 4)]
  )
)
(define (kube_external_services srcPort srcIP dstPort dstIP protocol ctstate)
  (cond
  [else (bv 5 4)]
  )
)
(define (kube_firewall srcPort srcIP dstPort dstIP protocol ctstate)
  (cond
  [(and #t (not (bveq (bvand srcIP (bv 4278190080 32)) (bv 2130706432 32))) (bveq (bvand dstIP (bv 4278190080 32)) (bv 2130706432 32)) #t) (bv 1 4)
]

  [else (bv 5 4)]
  )
)
(define (kube_nodeports srcPort srcIP dstPort dstIP protocol ctstate)
  (cond
  [else (bv 5 4)]
  )
)
(define (kube_proxy_firewall srcPort srcIP dstPort dstIP protocol ctstate)
  (cond
  [else (bv 5 4)]
  )
)

(define-symbolic mask0 mask0L mask0R (bitvector 32))
(define (impl srcPort srcIP dstPort dstIP protocol ctstate)
  (let* (

            ;; node 0 condition：
            [Const0    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 5 4) (bv 4278190080 32) (bv 2130706432 32))]

            [cond0
              (choose
                ;; IP branch (bvand (choose srcIP dstIP) mask) ?= ipConst
                ((choose bveq)
                   (bvand (choose srcIP dstIP) mask0)
                   Const0)
                ;; non IP branch
                ((choose bveq)
                   (choose srcPort dstPort protocol ctstate)
                   Const0))]
    

            ;; node 0L condition：
            [Const0L    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 5 4) (bv 4278190080 32) (bv 2130706432 32))]

            [cond0L
              (choose
                ;; IP branch (bvand (choose srcIP dstIP) mask) ?= ipConst
                ((choose bveq)
                   (bvand (choose srcIP dstIP) mask0L)
                   Const0L)
                ;; non IP branch
                ((choose bveq)
                   (choose srcPort dstPort protocol ctstate)
                   Const0L))]
    
    [choice0LL (choose 0 1 2 3)]
    [expr0LL (cond
        [(= choice0LL 0) (bv 0 4)]
        [(= choice0LL 1) (bv 1 4)]
        [else (bv 0 4)] ; default accept
            )]
    [choice0LR (choose 0 1 2 3)]
    [expr0LR (cond
        [(= choice0LR 0) (bv 0 4)]
        [(= choice0LR 1) (bv 1 4)]
        [else (bv 0 4)] ; default accept
            )]
    [expr0L (if cond0L expr0LL expr0LR)]

            ;; node 0R condition：
            [Const0R    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 5 4) (bv 4278190080 32) (bv 2130706432 32))]

            [cond0R
              (choose
                ;; IP branch (bvand (choose srcIP dstIP) mask) ?= ipConst
                ((choose bveq)
                   (bvand (choose srcIP dstIP) mask0R)
                   Const0R)
                ;; non IP branch
                ((choose bveq)
                   (choose srcPort dstPort protocol ctstate)
                   Const0R))]
    
    [choice0RL (choose 0 1 2 3)]
    [expr0RL (cond
        [(= choice0RL 0) (bv 0 4)]
        [(= choice0RL 1) (bv 1 4)]
        [else (bv 0 4)] ; default accept
            )]
    [choice0RR (choose 0 1 2 3)]
    [expr0RR (cond
        [(= choice0RR 0) (bv 0 4)]
        [(= choice0RR 1) (bv 1 4)]
        [else (bv 0 4)] ; default accept
            )]
    [expr0R (if cond0R expr0RL expr0RR)]
    [expr0 (if cond0 expr0L expr0R)]
        )
    expr0))


(define sol
   (synthesize
     #:forall    (list srcPort_sym dstPort_sym srcIP_sym dstIP_sym protocol_sym ctstate_sym)
     #:guarantee (begin
      (assert (bveq (input srcPort_sym srcIP_sym dstPort_sym dstIP_sym protocol_sym ctstate_sym) (impl srcPort_sym srcIP_sym dstPort_sym dstIP_sym protocol_sym ctstate_sym)))
    ))
)

(print-forms sol)
