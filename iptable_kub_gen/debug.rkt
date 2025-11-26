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
(define-symbolic mark_sym (bitvector 16))
(define-symbolic rand_sym (bitvector 8))


(define (list-bv-equal? l1 l2)
  (foldl (lambda (a acc) (and a acc))
         #t
         (map bveq l1 l2)))

;;; (define (kube_svc_tcou7jcqxezgvunu srcPort srcIP dstPort dstIP protocol ctstate mark rand)
;;; (list NOHIT srcPort srcIP dstPort dstIP protocol ctstate mark rand)
(define (list-bv-equal-new? l1 l2)
  (and 
      ;;; (bveq (list-ref l1 0) (list-ref l2 0))
      ;;;  (bveq (list-ref l1 1) (list-ref l2 1))
      ;;;  (bveq (list-ref l1 2) (list-ref l2 2))
      ;;;  (bveq (list-ref l1 3) (list-ref l2 3))
      ;;;  (bveq (list-ref l1 4) (list-ref l2 4))
      ;;;  (bveq (list-ref l1 5) (list-ref l2 5))
      ;;;  (bveq (list-ref l1 6) (list-ref l2 6))
       (bveq (list-ref l1 7) (list-ref l2 7))
      ;;;  (bveq (list-ref l1 8) (list-ref l2 8))
       ))

(define NEW (bv 0 4))
(define RELATED (bv 1 4))
(define ESTABLISHED (bv 2 4))
(define INVALID (bv 3 4))
(define DNAT (bv 4 4))
(define NOHIT (bv 5 4))
(define RETURN (bv 6 4))
(define MARK (bv 8 4))
(define (kube_svc_tcou7jcqxezgvunu srcPort srcIP dstPort dstIP protocol ctstate mark rand)
  (cond
  [(and (not (bveq (bvand srcIP (bv 4294901760 32)) (bv 183762944 32))) (bveq (bvand dstIP (bv 4294967295 32)) (bv 174063626 32))) (let* ([ret_list (kube_mark_masq srcPort srcIP dstPort dstIP protocol ctstate mark rand)]
      [decision (list-ref ret_list 0)]
      [mark (list-ref ret_list 7)])
      (if (and (not (bveq decision NOHIT)) (not (bveq decision RETURN)) (not (bveq decision MARK)))
            ret_list
            (cond
[#t (let* ([ret_list (kube_sep_wxwghgkzocnyryi7 srcPort srcIP dstPort dstIP protocol ctstate mark rand)]
      [decision (list-ref ret_list 0)]
      [mark (list-ref ret_list 7)])
      (if (and (not (bveq decision NOHIT)) (not (bveq decision RETURN)) (not (bveq decision MARK)))
            ret_list
            (list NOHIT srcPort srcIP dstPort dstIP protocol ctstate mark rand)))]
[else (list NOHIT srcPort srcIP dstPort dstIP protocol ctstate mark rand)])))]

  [#t (let* ([ret_list (kube_sep_wxwghgkzocnyryi7 srcPort srcIP dstPort dstIP protocol ctstate mark rand)]
      [decision (list-ref ret_list 0)]
      [mark (list-ref ret_list 7)])
      (if (and (not (bveq decision NOHIT)) (not (bveq decision RETURN)) (not (bveq decision MARK)))
            ret_list
            (list NOHIT srcPort srcIP dstPort dstIP protocol ctstate mark rand)))]

  [else (list NOHIT srcPort srcIP dstPort dstIP protocol ctstate mark rand)]
  )
)
(define (kube_mark_masq srcPort srcIP dstPort dstIP protocol ctstate mark rand)
  (cond
  [#t 
  (set! mark (bvor mark (bv 16384 16)))
(list MARK srcPort srcIP dstPort dstIP protocol ctstate mark rand)
]

  [else (list NOHIT srcPort srcIP dstPort dstIP protocol ctstate mark rand)]
  )
)
(define (kube_sep_wxwghgkzocnyryi7 srcPort srcIP dstPort dstIP protocol ctstate mark rand)
  (cond
  [(and (bveq (bvand srcIP (bv 4294967295 32)) (bv 183762948 32))) (let* ([ret_list (kube_mark_masq srcPort srcIP dstPort dstIP protocol ctstate mark rand)]
      [decision (list-ref ret_list 0)]
      [mark (list-ref ret_list 7)])
      (if (and (not (bveq decision NOHIT)) (not (bveq decision RETURN)) (not (bveq decision MARK)))
            ret_list
;;; (
;;;   let* (
;;;     [dstIP_new (bv 183762948 32)]    
;;;     [dstPort_new (bv 53 16)]
;;;   )
;;;   (list (bv 2 4) srcPort srcIP dstPort_new dstIP_new protocol ctstate mark rand)
;;; )
            (cond
[#t 
(let ([dstIP (bv 183762948 32)]
       [dstPort (bv 53 16)])
(list (bv 2 4) srcPort srcIP dstPort dstIP protocol ctstate mark rand))
]
[else (list NOHIT srcPort srcIP dstPort dstIP protocol ctstate mark rand)])))]

  [#t (set! dstIP (bv 183762948 32))
(set! dstPort (bv 53 16))
(list (bv 2 4) srcPort srcIP dstPort dstIP protocol ctstate mark rand)
]

  [else (list NOHIT srcPort srcIP dstPort dstIP protocol ctstate mark rand)]
  )
)


(define (impl1 srcPort srcIP dstPort dstIP protocol ctstate mark rand)
  (let* (
         ;; bitvector constants
         [mask-ffff0000 (bv #xffff0000 32)]
         [cluster-cidr  (bv #x0af40000 32)] ;; 10.244.0.0
         [svc-ip        (bv #x0a60000a 32)] ;; 10.96.0.10
         [sep-ip        (bv #x0af40004 32)] ;; 10.244.0.4
         [mark-bit      (bv #x4000 16)]
        )

    (if (and (not (bveq (bvand srcIP mask-ffff0000) cluster-cidr))
             (bveq dstIP svc-ip))

        ;; --------------------------
        ;; THEN branch
        ;; --------------------------
        (let* (
               ;; MARK |= 0x4000
               [mark1 (bvor mark mark-bit)]

               ;; inner if
               [mark2 (if (bveq srcIP sep-ip)
                          (bvor mark1 mark-bit)
                          mark1)]

               ;; DNAT to SEP IP
               [dstIP2 sep-ip]
               [dstPort2 (bv 53 16)]
              )
          (list (bv 2 4) srcPort srcIP dstPort2 dstIP2 protocol ctstate mark2 rand))

        ;; --------------------------
        ;; ELSE branch
        ;; --------------------------
        (let* (
               ;; inner if only
               [mark1 (if (bveq srcIP sep-ip)
                          (bvor mark mark-bit)
                          mark)]

               ;; same DNAT outside
               [dstIP2 sep-ip]
               [dstPort2 (bv 53 16)]
              )
          (list (bv 2 4) srcPort srcIP dstPort2 dstIP2 protocol ctstate mark1 rand)))))

(define (impl2 srcPort srcIP dstPort dstIP protocol ctstate mark rand)
  (let* (
         ;; bitvector constants
         [mask-ffff0000 (bv #xffff0000 32)]
         [cluster-cidr  (bv #x0af40000 32)] ;; 10.244.0.0
         [svc-ip        (bv #x0a60000a 32)] ;; 10.96.0.10
         [sep-ip        (bv #x0af40004 32)] ;; 10.244.0.4
         [mark-bit      (bv #x4000 16)]
        )

    (cond
      ;; if ((srcIP & mask) == cluster-cidr)
      [(bveq (bvand srcIP mask-ffff0000) cluster-cidr)
       (cond
         ;; if (srcIP == sep-ip)
         [(bveq srcIP sep-ip)
          ;; mark = mark | mark-bit
          (set! mark (bvor mark mark-bit))
          (set! dstPort (bv 53 16))
          (set! dstIP sep-ip)
          (list (bv 2 4) srcPort srcIP dstPort dstIP protocol ctstate mark rand)]

         [else
          ;; mark = mark
          (set! dstPort (bv 53 16))
          (set! dstIP sep-ip)
          (list (bv 2 4) srcPort srcIP dstPort dstIP protocol ctstate mark rand)]
         )]

      ;; else: (srcIP not in cluster cidr)
      [else
       (cond
         ;; if (dstIP == svc-ip)
         [(bveq dstIP svc-ip)
          (cond
            ;; if (srcIP == sep-ip)
            [(bveq srcIP sep-ip)
            (set! dstPort (bv 53 16))
            (set! dstIP sep-ip)
             ;; mark = mark
             (list (bv 2 4) srcPort srcIP dstPort dstIP protocol ctstate mark rand)]
            
            ;; else: mark |= bit
            [else
             (set! mark (bvor mark mark-bit))
             (set! dstPort (bv 53 16))
             (set! dstIP sep-ip)
             (list (bv 2 4) srcPort srcIP dstPort dstIP protocol ctstate mark rand)]
            )]

         ;; else: (dstIP != svc-ip)
         [else
          (cond
            ;; if (srcIP == sep-ip)
            [(bveq srcIP sep-ip)
             (set! mark (bvor mark mark-bit))
             (set! dstPort (bv 53 16))
             (set! dstIP sep-ip)
             (list (bv 2 4) srcPort srcIP dstPort dstIP protocol ctstate mark rand)]
            
            [else
             ;; mark = mark
             (set! dstPort (bv 53 16))
             (set! dstIP sep-ip)
             (list (bv 2 4) srcPort srcIP dstPort dstIP protocol ctstate mark rand)]
            )]
         )]
      )))

(define (impl_proved srcPort srcIP dstPort dstIP protocol ctstate mark rand)
  (let* (
            ;;; [mask0 (?? (bitvector 32))]
            ;;; [mask0L (?? (bitvector 32))]
            ;;; [mask0R (?? (bitvector 32))]
            ;;; [mask0LL (?? (bitvector 32))]
            ;;; [mask0LR (?? (bitvector 32))]
            ;;; [mask0RL (?? (bitvector 32))]
            ;;; [mask0RR (?? (bitvector 32))]
            [mark-bit      (bv #x4000 16)]

            [expr0RRR (cond
              [else
              (list (bv 2 4) srcPort srcIP dstPort dstIP protocol ctstate mark rand)]
                  )]
            [Const0RRL_mark_1    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 6 4) (bv 7 4) (bv 8 4) (bv 9 4) (bv 10 4) (bv 11 4) (bv 12 4) (bv 13 4) (bv 14 4) (bv 15 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]
            [Const0RRL_mark_2    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 6 4) (bv 7 4) (bv 8 4) (bv 9 4) (bv 10 4) (bv 11 4) (bv 12 4) (bv 13 4) (bv 14 4) (bv 15 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]
            [expr0RRL (cond
              [else 
              ;;; (set! mark (choose mark ((choose bvand bvor) mark Const0RRL_mark_2)))
              (let ([markexpr0RRL (bvor mark mark-bit)])
              (list (bv 2 4) srcPort srcIP dstPort dstIP protocol ctstate markexpr0RRL rand))]
                  )]
            [Const0RLR_mark_1    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 6 4) (bv 7 4) (bv 8 4) (bv 9 4) (bv 10 4) (bv 11 4) (bv 12 4) (bv 13 4) (bv 14 4) (bv 15 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]
            [Const0RLR_mark_2    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 6 4) (bv 7 4) (bv 8 4) (bv 9 4) (bv 10 4) (bv 11 4) (bv 12 4) (bv 13 4) (bv 14 4) (bv 15 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]
            [expr0RLR (cond
              [else 
              (let ([markexpr0RLR (bvor mark mark-bit)])
              ;;; (set! mark (choose mark ((choose bvand bvor) mark Const0RLR_mark_2)))
              (list (bv 2 4) srcPort srcIP dstPort dstIP protocol ctstate markexpr0RLR rand))]
                  )]
            [cond0RL (bveq srcIP (bv #x0af40004 32))]
            [cond0RR (bveq srcIP (bv #x0af40004 32))]
            [expr0RLL (cond
              [else 
              (list (bv 2 4) srcPort srcIP dstPort dstIP protocol ctstate mark rand)]
                  )]
            [expr0RL (if cond0RL expr0RLL expr0RLR)]
            [expr0RR (if cond0RR expr0RRL expr0RRR)]
            [expr0LR (list (bv 2 4) srcPort srcIP dstPort dstIP protocol ctstate mark rand)]
            [Const0LL_mark_1    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 6 4) (bv 7 4) (bv 8 4) (bv 9 4) (bv 10 4) (bv 11 4) (bv 12 4) (bv 13 4) (bv 14 4) (bv 15 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]
            [Const0LL_mark_2    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 6 4) (bv 7 4) (bv 8 4) (bv 9 4) (bv 10 4) (bv 11 4) (bv 12 4) (bv 13 4) (bv 14 4) (bv 15 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]
            ;;; (set! mark (choose mark ((choose bvor) mark Const0LL_mark_2)))
            [expr0LL (cond
                    [else 
                    (let ([markexpr0LL (bvor mark mark-bit)])
                    (list (bv 2 4) srcPort srcIP dstPort dstIP protocol ctstate markexpr0LL rand))] )]

            [cond0L (bveq srcIP (bv #x0af40004 32))]
            [cond0R (bveq dstIP (bv #x0a60000a 32))]
            [expr0L (if cond0L expr0LL expr0LR)]
            [expr0R (if cond0R expr0RL expr0RR)]
            [cond0 (bveq (bvand srcIP (bv #xffff0000 32)) (bv #x0af40000 32))]

            [expr0 (if cond0 expr0L expr0R)]
        )
    expr0))

(define (impl srcPort srcIP dstPort dstIP protocol ctstate mark rand)
  (let* (
            [mask0 (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]
            [mask0L (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]
            [mask0R (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]
            [mask0LL (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]
            [mask0LR (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]
            [mask0RL (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]
            [mask0RR (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]

            [Const0    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]

            [cond0
              (choose
                ((choose bveq)
                   (bvand (choose srcIP dstIP) mask0)
                   Const0)
                ((choose bveq)
                   (choose srcPort dstPort protocol ctstate mark rand)
                   Const0))]
    

            [Const0L    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]

            [cond0L
              (choose
                ((choose bveq)
                   (bvand (choose srcIP dstIP) mask0L)
                   Const0L)
                ((choose bveq)
                   (choose srcPort dstPort protocol ctstate mark rand)
                   Const0L))]
    

            [Const0LL    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]

            [cond0LL
              (choose
                ((choose bveq)
                   (bvand (choose srcIP dstIP) mask0LL)
                   Const0LL)
                ((choose bveq)
                   (choose srcPort dstPort protocol ctstate mark rand)
                   Const0LL))]
    
    [Const0LLL_dstPort_1    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]
    [Const0LLL_dstPort_2    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]
    [Const0LLL_dstIP_1    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]
    [Const0LLL_dstIP_2    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]
    [Const0LLL_ctstate_1    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]
    [Const0LLL_ctstate_2    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]
    [Const0LLL_mark_1    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]
    [Const0LLL_mark_2    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]
    [ret0LLL (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 6 4) (bv 7 4))]
    [expr0LLL (cond
        [else 
         (let* (
                [dstPort0LLL (choose dstPort ((choose bvand bvor) (choose dstPort Const0LLL_dstPort_1) Const0LLL_dstPort_2))]
                [dstIP0LLL (choose dstIP ((choose bvand bvor) (choose dstIP Const0LLL_dstIP_1) Const0LLL_dstIP_2))]
                [ctstate0LLL (choose ctstate ((choose bvand bvor) (choose ctstate Const0LLL_ctstate_1) Const0LLL_ctstate_2))]
                [mark0LLL (choose mark ((choose bvand bvor) (choose mark Const0LLL_mark_1) Const0LLL_mark_2))]
               )
         (list ret0LLL  srcPort srcIP dstPort0LLL dstIP0LLL protocol ctstate0LLL mark0LLL rand))]
            )]
    [Const0LLR_dstPort_1    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]
    [Const0LLR_dstPort_2    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]
    [Const0LLR_dstIP_1    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]
    [Const0LLR_dstIP_2    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]
    [Const0LLR_ctstate_1    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]
    [Const0LLR_ctstate_2    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]
    [Const0LLR_mark_1    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]
    [Const0LLR_mark_2    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]
    [ret0LLR (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 6 4) (bv 7 4))]
    [expr0LLR (cond
        [else 
         (let* (
                [dstPort0LLR (choose dstPort ((choose bvand bvor) (choose dstPort Const0LLR_dstPort_1) Const0LLR_dstPort_2))]
                [dstIP0LLR (choose dstIP ((choose bvand bvor) (choose dstIP Const0LLR_dstIP_1) Const0LLR_dstIP_2))]
                [ctstate0LLR (choose ctstate ((choose bvand bvor) (choose ctstate Const0LLR_ctstate_1) Const0LLR_ctstate_2))]
                [mark0LLR (choose mark ((choose bvand bvor) (choose mark Const0LLR_mark_1) Const0LLR_mark_2))]
               )
         (list ret0LLR  srcPort srcIP dstPort0LLR dstIP0LLR protocol ctstate0LLR mark0LLR rand))]
            )]
    [expr0LL (cond

        [else (if cond0LL expr0LLL expr0LLR)]
    )]

            [Const0LR    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]

            [cond0LR
              (choose
                ((choose bveq)
                   (bvand (choose srcIP dstIP) mask0LR)
                   Const0LR)
                ((choose bveq)
                   (choose srcPort dstPort protocol ctstate mark rand)
                   Const0LR))]
    
    [Const0LRL_dstPort_1    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]
    [Const0LRL_dstPort_2    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]
    [Const0LRL_dstIP_1    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]
    [Const0LRL_dstIP_2    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]
    [Const0LRL_ctstate_1    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]
    [Const0LRL_ctstate_2    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]
    [Const0LRL_mark_1    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]
    [Const0LRL_mark_2    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]
    [ret0LRL (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 6 4) (bv 7 4))]
    [expr0LRL (cond
        [else 
         (let* (
                [dstPort0LRL (choose dstPort ((choose bvand bvor) (choose dstPort Const0LRL_dstPort_1) Const0LRL_dstPort_2))]
                [dstIP0LRL (choose dstIP ((choose bvand bvor) (choose dstIP Const0LRL_dstIP_1) Const0LRL_dstIP_2))]
                [ctstate0LRL (choose ctstate ((choose bvand bvor) (choose ctstate Const0LRL_ctstate_1) Const0LRL_ctstate_2))]
                [mark0LRL (choose mark ((choose bvand bvor) (choose mark Const0LRL_mark_1) Const0LRL_mark_2))]
               )
         (list ret0LRL  srcPort srcIP dstPort0LRL dstIP0LRL protocol ctstate0LRL mark0LRL rand))]
            )]
    [Const0LRR_dstPort_1    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]
    [Const0LRR_dstPort_2    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]
    [Const0LRR_dstIP_1    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]
    [Const0LRR_dstIP_2    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]
    [Const0LRR_ctstate_1    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]
    [Const0LRR_ctstate_2    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]
    [Const0LRR_mark_1    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]
    [Const0LRR_mark_2    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]
    [ret0LRR (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 6 4) (bv 7 4))]
    [expr0LRR (cond
        [else 
         (let* (
                [dstPort0LRR (choose dstPort ((choose bvand bvor) (choose dstPort Const0LRR_dstPort_1) Const0LRR_dstPort_2))]
                [dstIP0LRR (choose dstIP ((choose bvand bvor) (choose dstIP Const0LRR_dstIP_1) Const0LRR_dstIP_2))]
                [ctstate0LRR (choose ctstate ((choose bvand bvor) (choose ctstate Const0LRR_ctstate_1) Const0LRR_ctstate_2))]
                [mark0LRR (choose mark ((choose bvand bvor) (choose mark Const0LRR_mark_1) Const0LRR_mark_2))]
               )
         (list ret0LRR  srcPort srcIP dstPort0LRR dstIP0LRR protocol ctstate0LRR mark0LRR rand))]
            )]
    [expr0LR (cond

        [else (if cond0LR expr0LRL expr0LRR)]
    )]
    [expr0L (cond

        [else (if cond0L expr0LL expr0LR)]
    )]

            [Const0R    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]

            [cond0R
              (choose
                ((choose bveq)
                   (bvand (choose srcIP dstIP) mask0R)
                   Const0R)
                ((choose bveq)
                   (choose srcPort dstPort protocol ctstate mark rand)
                   Const0R))]
    

            [Const0RL    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]

            [cond0RL
              (choose
                ((choose bveq)
                   (bvand (choose srcIP dstIP) mask0RL)
                   Const0RL)
                ((choose bveq)
                   (choose srcPort dstPort protocol ctstate mark rand)
                   Const0RL))]
    
    [Const0RLL_dstPort_1    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]
    [Const0RLL_dstPort_2    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]
    [Const0RLL_dstIP_1    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]
    [Const0RLL_dstIP_2    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]
    [Const0RLL_ctstate_1    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]
    [Const0RLL_ctstate_2    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]
    [Const0RLL_mark_1    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]
    [Const0RLL_mark_2    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]
    [ret0RLL (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 6 4) (bv 7 4))]
    [expr0RLL (cond
        [else 
         (let* (
                [dstPort0RLL (choose dstPort ((choose bvand bvor) (choose dstPort Const0RLL_dstPort_1) Const0RLL_dstPort_2))]
                [dstIP0RLL (choose dstIP ((choose bvand bvor) (choose dstIP Const0RLL_dstIP_1) Const0RLL_dstIP_2))]
                [ctstate0RLL (choose ctstate ((choose bvand bvor) (choose ctstate Const0RLL_ctstate_1) Const0RLL_ctstate_2))]
                [mark0RLL (choose mark ((choose bvand bvor) (choose mark Const0RLL_mark_1) Const0RLL_mark_2))]
               )
         (list ret0RLL  srcPort srcIP dstPort0RLL dstIP0RLL protocol ctstate0RLL mark0RLL rand))]
            )]
    [Const0RLR_dstPort_1    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]
    [Const0RLR_dstPort_2    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]
    [Const0RLR_dstIP_1    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]
    [Const0RLR_dstIP_2    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]
    [Const0RLR_ctstate_1    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]
    [Const0RLR_ctstate_2    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]
    [Const0RLR_mark_1    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]
    [Const0RLR_mark_2    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]
    [ret0RLR (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 6 4) (bv 7 4))]
    [expr0RLR (cond
        [else 
         (let* (
                [dstPort0RLR (choose dstPort ((choose bvand bvor) (choose dstPort Const0RLR_dstPort_1) Const0RLR_dstPort_2))]
                [dstIP0RLR (choose dstIP ((choose bvand bvor) (choose dstIP Const0RLR_dstIP_1) Const0RLR_dstIP_2))]
                [ctstate0RLR (choose ctstate ((choose bvand bvor) (choose ctstate Const0RLR_ctstate_1) Const0RLR_ctstate_2))]
                [mark0RLR (choose mark ((choose bvand bvor) (choose mark Const0RLR_mark_1) Const0RLR_mark_2))]
               )
         (list ret0RLR  srcPort srcIP dstPort0RLR dstIP0RLR protocol ctstate0RLR mark0RLR rand))]
            )]
    [expr0RL (cond

        [else (if cond0RL expr0RLL expr0RLR)]
    )]

            [Const0RR    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]

            [cond0RR
              (choose
                ((choose bveq)
                   (bvand (choose srcIP dstIP) mask0RR)
                   Const0RR)
                ((choose bveq)
                   (choose srcPort dstPort protocol ctstate mark rand)
                   Const0RR))]
    
    [Const0RRL_dstPort_1    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]
    [Const0RRL_dstPort_2    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]
    [Const0RRL_dstIP_1    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]
    [Const0RRL_dstIP_2    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]
    [Const0RRL_ctstate_1    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]
    [Const0RRL_ctstate_2    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]
    [Const0RRL_mark_1    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]
    [Const0RRL_mark_2    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]
    [ret0RRL (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 6 4) (bv 7 4))]
    [expr0RRL (cond
        [else 
         (let* (
                [dstPort0RRL (choose dstPort ((choose bvand bvor) (choose dstPort Const0RRL_dstPort_1) Const0RRL_dstPort_2))]
                [dstIP0RRL (choose dstIP ((choose bvand bvor) (choose dstIP Const0RRL_dstIP_1) Const0RRL_dstIP_2))]
                [ctstate0RRL (choose ctstate ((choose bvand bvor) (choose ctstate Const0RRL_ctstate_1) Const0RRL_ctstate_2))]
                [mark0RRL (choose mark ((choose bvand bvor) (choose mark Const0RRL_mark_1) Const0RRL_mark_2))]
               )
         (list ret0RRL  srcPort srcIP dstPort0RRL dstIP0RRL protocol ctstate0RRL mark0RRL rand))]
            )]
    [Const0RRR_dstPort_1    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]
    [Const0RRR_dstPort_2    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]
    [Const0RRR_dstIP_1    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]
    [Const0RRR_dstIP_2    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]
    [Const0RRR_ctstate_1    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]
    [Const0RRR_ctstate_2    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]
    [Const0RRR_mark_1    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]
    [Const0RRR_mark_2    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]
    [ret0RRR (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 6 4) (bv 7 4))]
    [expr0RRR (cond
        [else 
         (let* (
                [dstPort0RRR (choose dstPort ((choose bvand bvor) (choose dstPort Const0RRR_dstPort_1) Const0RRR_dstPort_2))]
                [dstIP0RRR (choose dstIP ((choose bvand bvor) (choose dstIP Const0RRR_dstIP_1) Const0RRR_dstIP_2))]
                [ctstate0RRR (choose ctstate ((choose bvand bvor) (choose ctstate Const0RRR_ctstate_1) Const0RRR_ctstate_2))]
                [mark0RRR (choose mark ((choose bvand bvor) (choose mark Const0RRR_mark_1) Const0RRR_mark_2))]
               )
         (list ret0RRR  srcPort srcIP dstPort0RRR dstIP0RRR protocol ctstate0RRR mark0RRR rand))]
            )]
    [expr0RR (cond

        [else (if cond0RR expr0RRL expr0RRR)]
    )]
    [expr0R (cond

        [else (if cond0R expr0RL expr0RR)]
    )]
    [expr0 (cond

        [else (if cond0 expr0L expr0R)]
    )]
        )
    expr0))

(define (impl_gen srcPort srcIP dstPort dstIP protocol ctstate mark rand)
  (let* ((mask0 (bv 0 32))
         (mask0L (bv 4294901760 32))
         (mask0R (bv 4294901760 32))
         (mask0LL (bv 4294967295 32))
         (mask0LR (bv 4294967295 32))
         (mask0RL (bv 4294967295 32))
         (mask0RR (bv 174063626 32))
         (Const0 (bv 0 32))
         (cond0 ((choose bveq) (bvand dstIP mask0) Const0))
         (Const0L (bv 183762944 32))
         (cond0L ((choose bveq) (bvand srcIP mask0L) Const0L))
         (Const0LL (bv 183762948 32))
         (cond0LL ((choose bveq) (bvand srcIP mask0LL) Const0LL))
         (Const0LLL_dstPort_1 (bv 53 16))
         (Const0LLL_dstPort_2 (bv 53 16))
         (Const0LLL_dstIP_1 (bv 183762944 32))
         (Const0LLL_dstIP_2 (bv 183762948 32))
         (Const0LLL_ctstate_1 (bv 16384 16))
         (Const0LLL_ctstate_2 (bv 1 4))
         (Const0LLL_mark_1 (bv 4294967295 32))
         (Const0LLL_mark_2 (bv 16384 16))
         (ret0LLL (bv 2 4))
         (expr0LLL
          (cond
           (else
            (let* ((dstPort0LLL
                    (bvand Const0LLL_dstPort_1 Const0LLL_dstPort_2))
                   (dstIP0LLL (bvor Const0LLL_dstIP_1 Const0LLL_dstIP_2))
                   (ctstate0LLL ctstate)
                   (mark0LLL (bvor mark Const0LLL_mark_2)))
              (list
               ret0LLL
               srcPort
               srcIP
               dstPort0LLL
               dstIP0LLL
               protocol
               ctstate0LLL
               mark0LLL
               rand)))))
         (Const0LLR_dstPort_1 (bv 53 16))
         (Const0LLR_dstPort_2 (bv 53 16))
         (Const0LLR_dstIP_1 (bv 183762944 32))
         (Const0LLR_dstIP_2 (bv 183762948 32))
         (Const0LLR_ctstate_1 (bv 53 16))
         (Const0LLR_ctstate_2 (bv 53 16))
         (Const0LLR_mark_1 (bv 0 32))
         (Const0LLR_mark_2 (bv 53 16))
         (ret0LLR (bv 2 4))
         (expr0LLR
          (cond
           (else
            (let* ((dstPort0LLR (bvor Const0LLR_dstPort_1 Const0LLR_dstPort_2))
                   (dstIP0LLR (bvor Const0LLR_dstIP_1 Const0LLR_dstIP_2))
                   (ctstate0LLR ctstate)
                   (mark0LLR mark))
              (list
               ret0LLR
               srcPort
               srcIP
               dstPort0LLR
               dstIP0LLR
               protocol
               ctstate0LLR
               mark0LLR
               rand)))))
         (expr0LL (cond (else (if cond0LL expr0LLL expr0LLR))))
         (Const0LR (bv 174063626 32))
         (cond0LR ((choose bveq) (bvand dstIP mask0LR) Const0LR))
         (Const0LRL_dstPort_1 (bv 53 16))
         (Const0LRL_dstPort_2 (bv 53 16))
         (Const0LRL_dstIP_1 (bv 183762948 32))
         (Const0LRL_dstIP_2 (bv 183762948 32))
         (Const0LRL_ctstate_1 (bv 4294967295 32))
         (Const0LRL_ctstate_2 (bv 183762948 32))
         (Const0LRL_mark_1 (bv 5 4))
         (Const0LRL_mark_2 (bv 16384 16))
         (ret0LRL (bv 2 4))
         (expr0LRL
          (cond
           (else
            (let* ((dstPort0LRL (bvor Const0LRL_dstPort_1 Const0LRL_dstPort_2))
                   (dstIP0LRL (bvand Const0LRL_dstIP_1 Const0LRL_dstIP_2))
                   (ctstate0LRL ctstate)
                   (mark0LRL (bvor mark Const0LRL_mark_2)))
              (list
               ret0LRL
               srcPort
               srcIP
               dstPort0LRL
               dstIP0LRL
               protocol
               ctstate0LRL
               mark0LRL
               rand)))))
         (Const0LRR_dstPort_1 (bv 53 16))
         (Const0LRR_dstPort_2 (bv 53 16))
         (Const0LRR_dstIP_1 (bv 183762948 32))
         (Const0LRR_dstIP_2 (bv 4294967295 32))
         (Const0LRR_ctstate_1 (bv 183762944 32))
         (Const0LRR_ctstate_2 (bv 1 4))
         (Const0LRR_mark_1 (bv 174063626 32))
         (Const0LRR_mark_2 (bv 53 16))
         (ret0LRR (bv 2 4))
         (expr0LRR
          (cond
           (else
            (let* ((dstPort0LRR
                    (bvand Const0LRR_dstPort_1 Const0LRR_dstPort_2))
                   (dstIP0LRR (bvand Const0LRR_dstIP_1 Const0LRR_dstIP_2))
                   (ctstate0LRR ctstate)
                   (mark0LRR mark))
              (list
               ret0LRR
               srcPort
               srcIP
               dstPort0LRR
               dstIP0LRR
               protocol
               ctstate0LRR
               mark0LRR
               rand)))))
         (expr0LR (cond (else (if cond0LR expr0LRL expr0LRR))))
         (expr0L (cond (else (if cond0L expr0LL expr0LR))))
         (Const0R (bv 53 16))
         (cond0R ((choose bveq) srcPort Const0R))
         (Const0RL (bv 53 16))
         (cond0RL ((choose bveq) dstPort Const0RL))
         (Const0RLL_dstPort_1 (bv 0 4))
         (Const0RLL_dstPort_2 (bv 4 4))
         (Const0RLL_dstIP_1 (bv 0 4))
         (Const0RLL_dstIP_2 (bv 5 4))
         (Const0RLL_ctstate_1 (bv 4294967295 32))
         (Const0RLL_ctstate_2 (bv 174063626 32))
         (Const0RLL_mark_1 (bv 174063626 32))
         (Const0RLL_mark_2 (bv 174063626 32))
         (ret0RLL (bv 2 4))
         (expr0RLL
          (cond
           (else
            (let* ((dstPort0RLL (bvor Const0RLL_dstPort_1 Const0RLL_dstPort_2))
                   (dstIP0RLL (bvor Const0RLL_dstIP_1 Const0RLL_dstIP_2))
                   (ctstate0RLL (bvor Const0RLL_ctstate_1 Const0RLL_ctstate_2))
                   (mark0RLL (bvor Const0RLL_mark_1 Const0RLL_mark_2)))
              (list
               ret0RLL
               srcPort
               srcIP
               dstPort0RLL
               dstIP0RLL
               protocol
               ctstate0RLL
               mark0RLL
               rand)))))
         (Const0RLR_dstPort_1 (bv 16384 16))
         (Const0RLR_dstPort_2 (bv 53 16))
         (Const0RLR_dstIP_1 (bv 183762948 32))
         (Const0RLR_dstIP_2 (bv 4294901760 32))
         (Const0RLR_ctstate_1 (bv 4294901760 32))
         (Const0RLR_ctstate_2 (bv 3 4))
         (Const0RLR_mark_1 (bv 16384 16))
         (Const0RLR_mark_2 (bv 53 16))
         (ret0RLR (bv 2 4))
         (expr0RLR
          (cond
           (else
            (let* ((dstPort0RLR (bvor Const0RLR_dstPort_1 Const0RLR_dstPort_2))
                   (dstIP0RLR (bvor Const0RLR_dstIP_1 Const0RLR_dstIP_2))
                   (ctstate0RLR ctstate)
                   (mark0RLR (bvor mark Const0RLR_mark_2)))
              (list
               ret0RLR
               srcPort
               srcIP
               dstPort0RLR
               dstIP0RLR
               protocol
               ctstate0RLR
               mark0RLR
               rand)))))
         (expr0RL (cond (else (if cond0RL expr0RLL expr0RLR))))
         (Const0RR (bv 0 4))
         (cond0RR ((choose bveq) ctstate Const0RR))
         (Const0RRL_dstPort_1 (bv 183762948 32))
         (Const0RRL_dstPort_2 (bv 0 32))
         (Const0RRL_dstIP_1 (bv 53 16))
         (Const0RRL_dstIP_2 (bv 0 32))
         (Const0RRL_ctstate_1 (bv 16384 16))
         (Const0RRL_ctstate_2 (bv 0 32))
         (Const0RRL_mark_1 (bv 16384 16))
         (Const0RRL_mark_2 (bv 16384 16))
         (ret0RRL (bv 0 4))
         (expr0RRL
          (cond
           (else
            (let* ((dstPort0RRL (bvor Const0RRL_dstPort_1 Const0RRL_dstPort_2))
                   (dstIP0RRL (bvor dstIP Const0RRL_dstIP_2))
                   (ctstate0RRL ctstate)
                   (mark0RRL (bvand mark Const0RRL_mark_2)))
              (list
               ret0RRL
               srcPort
               srcIP
               dstPort0RRL
               dstIP0RRL
               protocol
               ctstate0RRL
               mark0RRL
               rand)))))
         (Const0RRR_dstPort_1 (bv 53 16))
         (Const0RRR_dstPort_2 (bv 53 16))
         (Const0RRR_dstIP_1 (bv 0 32))
         (Const0RRR_dstIP_2 (bv 183762948 32))
         (Const0RRR_ctstate_1 (bv 3 4))
         (Const0RRR_ctstate_2 (bv 0 4))
         (Const0RRR_mark_1 (bv 0 32))
         (Const0RRR_mark_2 (bv 0 32))
         (ret0RRR (bv 2 4))
         (expr0RRR
          (cond
           (else
            (let* ((dstPort0RRR (bvor Const0RRR_dstPort_1 Const0RRR_dstPort_2))
                   (dstIP0RRR (bvor Const0RRR_dstIP_1 Const0RRR_dstIP_2))
                   (ctstate0RRR (bvor ctstate Const0RRR_ctstate_2))
                   (mark0RRR (bvor Const0RRR_mark_1 Const0RRR_mark_2)))
              (list
               ret0RRR
               srcPort
               srcIP
               dstPort0RRR
               dstIP0RRR
               protocol
               ctstate0RRR
               mark0RRR
               rand)))))
         (expr0RR (cond (else (if cond0RR expr0RRL expr0RRR))))
         (expr0R (cond (else (if cond0R expr0RL expr0RR))))
         (expr0 (cond (else (if cond0 expr0L expr0R)))))
    expr0))

(define (impl_depth2 srcPort srcIP dstPort dstIP protocol ctstate mark rand)
  (let* (
            [mask0 (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]
            [mask0L (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]
            [mask0R (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]

            [Const0    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]

            [cond0
              (choose
                ((choose bveq)
                   (bvand (choose srcIP dstIP) mask0)
                   Const0)
                ((choose bveq)
                   (choose srcPort dstPort protocol ctstate mark rand)
                   Const0))]
    

            [Const0L    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]

            [cond0L
              (choose
                ((choose bveq)
                   (bvand (choose srcIP dstIP) mask0L)
                   Const0L)
                ((choose bveq)
                   (choose srcPort dstPort protocol ctstate mark rand)
                   Const0L))]
    
    [Const0LL_dstPort_1    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]
    [Const0LL_dstPort_2    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]
    [Const0LL_dstIP_1    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]
    [Const0LL_dstIP_2    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]
    [Const0LL_ctstate_1    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]
    [Const0LL_ctstate_2    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]
    [Const0LL_mark_1    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]
    [Const0LL_mark_2    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]
    [ret0LL (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 6 4) (bv 7 4))]
    [expr0LL (cond
        [else 
         (let* (
                [dstPort0LL (choose dstPort ((choose bvand bvor) (choose dstPort Const0LL_dstPort_1) Const0LL_dstPort_2))]
                [dstIP0LL (choose dstIP ((choose bvand bvor) (choose dstIP Const0LL_dstIP_1) Const0LL_dstIP_2))]
                [ctstate0LL (choose ctstate ((choose bvand bvor) (choose ctstate Const0LL_ctstate_1) Const0LL_ctstate_2))]
                [mark0LL (choose mark ((choose bvand bvor) (choose mark Const0LL_mark_1) Const0LL_mark_2))]
               )
         (list ret0LL  srcPort srcIP dstPort0LL dstIP0LL protocol ctstate0LL mark0LL rand))]
            )]
    [Const0LR_dstPort_1    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]
    [Const0LR_dstPort_2    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]
    [Const0LR_dstIP_1    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]
    [Const0LR_dstIP_2    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]
    [Const0LR_ctstate_1    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]
    [Const0LR_ctstate_2    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]
    [Const0LR_mark_1    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]
    [Const0LR_mark_2    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]
    [ret0LR (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 6 4) (bv 7 4))]
    [expr0LR (cond
        [else 
         (let* (
                [dstPort0LR (choose dstPort ((choose bvand bvor) (choose dstPort Const0LR_dstPort_1) Const0LR_dstPort_2))]
                [dstIP0LR (choose dstIP ((choose bvand bvor) (choose dstIP Const0LR_dstIP_1) Const0LR_dstIP_2))]
                [ctstate0LR (choose ctstate ((choose bvand bvor) (choose ctstate Const0LR_ctstate_1) Const0LR_ctstate_2))]
                [mark0LR (choose mark ((choose bvand bvor) (choose mark Const0LR_mark_1) Const0LR_mark_2))]
               )
         (list ret0LR  srcPort srcIP dstPort0LR dstIP0LR protocol ctstate0LR mark0LR rand))]
            )]
    [expr0L (cond

        [else (if cond0L expr0LL expr0LR)]
    )]

            [Const0R    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]

            [cond0R
              (choose
                ((choose bveq)
                   (bvand (choose srcIP dstIP) mask0R)
                   Const0R)
                ((choose bveq)
                   (choose srcPort dstPort protocol ctstate mark rand)
                   Const0R))]
    
    [Const0RL_dstPort_1    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]
    [Const0RL_dstPort_2    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]
    [Const0RL_dstIP_1    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]
    [Const0RL_dstIP_2    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]
    [Const0RL_ctstate_1    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]
    [Const0RL_ctstate_2    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]
    [Const0RL_mark_1    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]
    [Const0RL_mark_2    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]
    [ret0RL (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 6 4) (bv 7 4))]
    [expr0RL (cond
        [else 
         (let* (
                [dstPort0RL (choose dstPort ((choose bvand bvor) (choose dstPort Const0RL_dstPort_1) Const0RL_dstPort_2))]
                [dstIP0RL (choose dstIP ((choose bvand bvor) (choose dstIP Const0RL_dstIP_1) Const0RL_dstIP_2))]
                [ctstate0RL (choose ctstate ((choose bvand bvor) (choose ctstate Const0RL_ctstate_1) Const0RL_ctstate_2))]
                [mark0RL (choose mark ((choose bvand bvor) (choose mark Const0RL_mark_1) Const0RL_mark_2))]
               )
         (list ret0RL  srcPort srcIP dstPort0RL dstIP0RL protocol ctstate0RL mark0RL rand))]
            )]
    [Const0RR_dstPort_1    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]
    [Const0RR_dstPort_2    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]
    [Const0RR_dstIP_1    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]
    [Const0RR_dstIP_2    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]
    [Const0RR_ctstate_1    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]
    [Const0RR_ctstate_2    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]
    [Const0RR_mark_1    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]
    [Const0RR_mark_2    (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 0 32) (bv 4294901760 32) (bv 183762944 32) (bv 4294967295 32) (bv 174063626 32) (bv 16384 16) (bv 183762948 32) (bv 53 16))]
    [ret0RR (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 3 4) (bv 4 4) (bv 5 4) (bv 6 4) (bv 7 4))]
    [expr0RR (cond
        [else 
         (let* (
                [dstPort0RR (choose dstPort ((choose bvand bvor) (choose dstPort Const0RR_dstPort_1) Const0RR_dstPort_2))]
                [dstIP0RR (choose dstIP ((choose bvand bvor) (choose dstIP Const0RR_dstIP_1) Const0RR_dstIP_2))]
                [ctstate0RR (choose ctstate ((choose bvand bvor) (choose ctstate Const0RR_ctstate_1) Const0RR_ctstate_2))]
                [mark0RR (choose mark ((choose bvand bvor) (choose mark Const0RR_mark_1) Const0RR_mark_2))]
               )
         (list ret0RR  srcPort srcIP dstPort0RR dstIP0RR protocol ctstate0RR mark0RR rand))]
            )]
    [expr0R (cond

        [else (if cond0R expr0RL expr0RR)]
    )]
    [expr0 (cond

        [else (if cond0 expr0L expr0R)]
    )]
        )
    expr0))



(print "impl2")
(impl2 (bv 0 16) (bv #x0af4fffb 32) (bv 0 16) (bv #xf59ffff5 32) (bv 0 8) (bv 0 4) (bv #x0000 16) (bv 0 8))
;;; (print "impl")
;;; (impl  (bv 0 16) (bv #x0af4fffb 32) (bv 0 16) (bv #xf59ffff5 32) (bv 0 8) (bv 0 4) (bv #x0000 16) (bv 0 8))

;;; (define ce
;;;   (verify
;;;     (assert
;;;        (list-bv-equal? 
;;;          (impl2 srcPort_sym srcIP_sym dstPort_sym dstIP_sym protocol_sym ctstate_sym mark_sym rand_sym)
;;;          (kube_svc_tcou7jcqxezgvunu  srcPort_sym srcIP_sym dstPort_sym dstIP_sym protocol_sym ctstate_sym mark_sym rand_sym)))))

;;; (print ce)

(define sol
   (synthesize
     #:forall    (list srcPort_sym dstPort_sym srcIP_sym dstIP_sym protocol_sym ctstate_sym mark_sym rand_sym)
     #:guarantee (begin
      (assert (list-bv-equal? (impl2 srcPort_sym srcIP_sym dstPort_sym dstIP_sym protocol_sym ctstate_sym mark_sym rand_sym) 
                              (impl_depth2 srcPort_sym srcIP_sym dstPort_sym dstIP_sym protocol_sym ctstate_sym mark_sym rand_sym)))
    ))
)

(print-forms sol)

;;; debug only (Successful synthesis)
;;; (define (list-bv-equal-debug? l1 l2)
;;;   (and 
;;;        (bveq (list-ref l1 0) (list-ref l2 0))
;;;        (bveq (list-ref l1 1) (list-ref l2 1))
;;;        (bveq (list-ref l1 2) (list-ref l2 2))
;;;        (bveq (list-ref l1 3) (list-ref l2 3))
;;;        (bveq (list-ref l1 4) (list-ref l2 4))
;;;        (bveq (list-ref l1 5) (list-ref l2 5))
;;;        (bveq (list-ref l1 6) (list-ref l2 6))
;;;        (bveq (list-ref l1 7) (list-ref l2 7))
;;;        (bveq (list-ref l1 8) (list-ref l2 8))
;;;        ))
;;; (define sol
;;;    (synthesize
;;;      #:forall    (list srcPort_sym dstPort_sym srcIP_sym dstIP_sym protocol_sym ctstate_sym mark_sym rand_sym)
;;;      #:guarantee (begin
;;;       (assert (list-bv-equal-debug? (kube_svc_tcou7jcqxezgvunu srcPort_sym srcIP_sym dstPort_sym dstIP_sym protocol_sym ctstate_sym mark_sym rand_sym) 
;;;                               (impl1 srcPort_sym srcIP_sym dstPort_sym dstIP_sym protocol_sym ctstate_sym mark_sym rand_sym)))
;;;     ))
;;; )

;;; (print-forms sol)