#lang rosette
(require rosette/lib/synthax)

(define-symbolic x integer?)

(define spec (cons 1 2))
(define tgt (cons 1 x))

(define sol (synthesize #:forall (list)
                          #:guarantee (assert (equal? spec tgt))))

(evaluate x sol)