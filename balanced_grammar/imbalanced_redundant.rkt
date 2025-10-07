#lang rosette/safe

(require rosette/lib/synthax)

(define-symbolic srcip (bitvector 32))
(define-symbolic dstip (bitvector 32))
(define-symbolic proto (bitvector 8))
(define-symbolic sport (bitvector 16))
(define-symbolic dport (bitvector 16))

(define-grammar (const8)
  [cst (choose (bv 0 8) (bv 1 8) (bv 6 8))])

(define-grammar (const32)
  [cst (choose (bv 0 32) (bv 1 32) (bv 42 32))])

(define-grammar (const16)
  [cst (choose (bv 0 16) (bv 1 16) (bv 42 16) (bv 80 16) (bv 433 16) (bv 21 16) (bv 135 16) (bv 445 16))])

(define-grammar (condition-grammar srcip dstip proto sport dport)
  [cst (choose #t 
              (equal? srcip (const32))
              (equal? dstip (const32))
              (equal? proto (const8))
              (equal? sport (const16))
              (equal? dport (const16))
              (and (cst) (cst))
              (or (cst) (cst)))])

(define (condition-expand srcip dstip proto sport dport)
  (condition-grammar srcip dstip proto sport dport #:depth 4))

(define-grammar (Impl_grammar srcip dstip proto sport dport)
    [expr
   (choose
    (if (cond-expr) (expr) (expr))
    (const8)
    (const8) ; return type
    )]
    [cond-expr
   (choose
    #t
    (equal? (vexpr) (vexpr))
    (and (cond-expr) (cond-expr))
    (or (cond-expr) (cond-expr))
    )]
    [vexpr
   (choose
    srcip
    dstip
    proto
    sport
    dport
    (const8)
    (const16)
    (const32))]     
) 

(define (spec srcip dstip proto sport dport)
  (if (and (bveq dport (bv 80 16)) (bveq sport (bv 80 16))) (bv 1 8) 
  (if (and (bveq dport (bv 80 16)) (bveq sport (bv 80 16))) (bv 1 8) (bv 0 8))))

(define (impleBPF srcip dstip proto sport dport)
  (Impl_grammar srcip dstip proto sport dport #:depth 4))


(define (impl2 srcip dstip proto sport dport)
  (if (and (choose (bveq proto (const8)) #t)
           (choose (bveq srcip (const32)) #t)
           (choose (bveq dstip (const32)) #t)
           (choose (bveq sport (const16)) #t)
           (choose (bveq dport (const16)) #t))
      (const8) (const8))
)

(define sol
  (synthesize
   #:forall (list srcip dstip proto sport dport)
   #:guarantee
   (begin
    (assert (bveq (spec srcip dstip proto sport dport) (impl2 srcip dstip proto sport dport)))
   )
   ))

(print-forms sol)
