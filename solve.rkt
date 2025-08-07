#lang rosette/safe

(define-symbolic x (bitvector 8))
(define-symbolic y (bitvector 8))

(define (f x)
  (cond
    [(bvult x (bv 10 8)) (bvadd x (bv 5 8))]
    [else               (bvsub x (bv 5 8))]))

(define result (f (bv 7 8)))
(displayln result)                      ; prints bitvector like #x0c (12)

(define sol
  (solve
   (assert (equal? (f x) (bv 12 8))))

  )

(displayln sol)
