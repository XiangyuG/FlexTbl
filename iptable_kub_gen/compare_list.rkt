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

(input (bv 3 4) (bv 2 4) (bv 10 4) (bv 20 4) (bv 1 4) (bv 0 2))

(define otherL (list (bv 0 1) (bv 3 4) (bv 2 4) (bv 10 4) (bv 20 4) (bv 1 4) (bv 0 2)))

(list-bv-equal? otherL (input (bv 3 4) (bv 2 4) (bv 10 4) (bv 20 4) (bv 1 4) (bv 0 2)))