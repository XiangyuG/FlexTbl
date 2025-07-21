#lang rosette

(require rosette/lib/synthax)     ; Require the sketching library.

(define int32? (bitvector 32))
(define (int32 i)
  (bv i int32?))

(define-symbolic proto port int32?)


(define-grammar (Impl_grammar x y)
  [expr
   (choose
    (if (cond-expr) (expr) (expr))
    (?? int32?))]

  [cond-expr
   (choose
    (equal? (vexpr) (vexpr))
    (and (cond-expr) (cond-expr))
    (or (cond-expr) (cond-expr))
    (not (cond-expr)))]
  [vexpr
   (choose
    x
    y
    (?? int32?))]     
  )
  

(define (impl-fast lo hi)
  (Impl_grammar lo hi #:depth 3))

;;; (define (Spec proto port)
;;;   (if (and (equal? proto (int32 1)) (equal? port (int32 22)))
;;;       (int32 1)
;;;       (int32 0)))
(define (Spec proto port)
  (if (and (equal? proto (int32 1)) (equal? port (int32 22)))
      (int32 1)
      (int32 0))
      ;;; (if (and (equal? proto (int32 0)) (equal? port (int32 22)))
      ;;;     (int32 1)
      ;;;     (int32 0)))
          ) ; Default case, return 0 if no match

(define sol
    (synthesize
     #:forall    (list proto port)
     #:guarantee (assert (equal? (impl-fast proto port) (Spec proto port)))))

(define sol-str
  (with-output-to-string
    (lambda () (print-forms sol))))

(displayln sol-str)