#lang rosette/safe

;;; (require racket/base)  ;; this loc would cause wrong solve solution

(define-symbolic x (bitvector 8))

(define (f x)
  (cond
    [(bvult x (bv 10 8)) (bvadd x (bv 5 8))]
    [else               (bvsub x (bv 5 8))]))

(define sol
  (solve
   (assert (equal? (f x) (bv 12 8))))
  )

(displayln sol)
