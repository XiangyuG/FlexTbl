#lang rosette

(require rosette/lib/synthax)     ; Require the sketching library.

(define int32? (bitvector 32))
(define (int32 i)
  (bv i int32?))

(define-symbolic l h int32?)

(define-grammar (Impl_grammar x y)
  [expr
   (choose
    (bvadd (expr) (expr))
    x
    y
    (?? int32?))])

(define (impl-fast lo hi)
  (Impl_grammar lo hi #:depth 2))

(define (Spec proto port)
  (bvadd proto port))

(define sol
    (synthesize
     #:forall    (list l h)
     #:guarantee (assert (equal? (impl-fast l h) (Spec l h)))))

(define sol-str
  (with-output-to-string
    (lambda () (print-forms sol))))

(displayln sol-str)