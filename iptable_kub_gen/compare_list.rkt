#lang rosette/safe

(require rosette/lib/synthax)
(require rosette/base/base)
(require rosette/solver/smt/z3)

;; --- symbolic inputs ---
(define-symbolic srcPort_sym (bitvector 4))
(define-symbolic srcIP_sym (bitvector 4))
(define-symbolic dstPort_sym (bitvector 4))
(define-symbolic dstIP_sym (bitvector 4))
(define-symbolic protocol_sym (bitvector 4))
(define-symbolic ctstate_sym (bitvector 2))


(define (list-bv-equal? l1 l2)
  (foldl (lambda (a acc) (and a acc))
         #t
         (map bveq l1 l2)))


(define (input srcPort dstPort srcIP dstIP protocol ctstate)
    (let ([decision (bv 0 1)])
    (list decision srcPort dstPort srcIP dstIP protocol ctstate))
)

(define (impl srcPort dstPort srcIP dstIP protocol ctstate)
    (let ([new_decision (choose (bv 0 1) (bv 1 1))]
         [new_srcPort (choose srcPort (bv 0 4))]
         [new_dstPort (choose dstPort (bv 0 4))]
         [new_srcIP (choose srcIP (bv 0 4))]
         [new_dstIP (choose dstIP (bv 0 4))]
         [new_protocol (choose protocol (bv 0 4))]
         [new_ctstate (choose ctstate (bv 0 2))])        

    (list new_decision new_srcPort new_dstPort new_srcIP new_dstIP new_protocol new_ctstate))
)

(input (bv 3 4) (bv 2 4) (bv 10 4) (bv 20 4) (bv 1 4) (bv 0 2))

(define otherL (list (bv 0 1) (bv 3 4) (bv 2 4) (bv 10 4) (bv 20 4) (bv 1 4) (bv 0 2)))

(list-bv-equal? otherL (input (bv 3 4) (bv 2 4) (bv 10 4) (bv 20 4) (bv 1 4) (bv 0 2)))



(define sol
   (synthesize
     #:forall    (list srcPort_sym dstPort_sym srcIP_sym dstIP_sym protocol_sym ctstate_sym)
     #:guarantee (begin
    ;;;   (assume (or (equal? proto_sym (int32 0)) (equal? proto_sym (int32 1))))
      (assert (list-bv-equal? (input srcPort_sym dstPort_sym srcIP_sym dstIP_sym protocol_sym ctstate_sym) (impl srcPort_sym dstPort_sym srcIP_sym dstIP_sym protocol_sym ctstate_sym)))
    ))
)

(print-forms sol)
