#lang rosette

(require rosette/lib/synthax)     ; Require the sketching library.

(define int32? (bitvector 32))
(define (int32 i)
  (bv i int32?))

;;; (define (check-mid impl lo hi)     ; Assuming that
;;;   (assume (bvsle (int32 0) lo))    ; 0 ≤ lo and
;;;   (assume (bvsle lo hi))           ; lo ≤ hi,
;;;   (define mi (impl lo hi))         ; and letting mi = impl(lo, hi) and
;;;   (define diff                     ; diff = (hi - mi) - (mi - lo),
;;;     (bvsub (bvsub hi mi)
;;;            (bvsub mi lo)))         ; we require that
;;;   (assert (bvsle lo mi))           ; lo ≤ mi,
;;;   (assert (bvsle mi hi))           ; mi ≤ hi,
;;;   (assert (bvsle (int32 0) diff))  ; 0 ≤ diff, and
;;;   (assert (bvsle diff (int32 1)))) ; diff ≤ 1.


(define-grammar (fast-int32 x y)  ; Grammar of int32 expressions over two inputs:
  [expr
   (choose x y (?? int32?)        ; <expr> := x | y | <32-bit integer constant> |
           ((bop) (expr) (expr))  ;           (<bop> <expr> <expr>) |
           )]
  [bop
   (choose bvadd bvsub bvand      ; <bop>  := bvadd  | bvsub | bvand |
           bvor bvxor bvshl       ;           bvor   | bvxor | bvshl |
           bvlshr bvashr)]        ;           bvlshr | bvashr
  )

(define-symbolic l h int32?)

;;; (define (bvmid-fast lo hi)
;;;   (fast-int32 lo hi #:depth 2))

;;; (define-grammar (Impl_grammar x y)
;;;   [expr
;;;    (choose
;;;     (if (and (equal? x (int32 0)) (equal? y (int32 0))) (expr) (expr))
;;;     (bvadd (expr) (expr))
;;;     (bvsub (expr) (expr))
;;;     x
;;;     y
;;;     (?? int32?))]
;;;   )

;;; (define (impl-fast lo hi)
;;;   (Impl_grammar lo hi #:depth 3))

;;; (define (Spec x y)
;;;   (if (and (equal? x (int32 1))
;;;            (equal? y (int32 0)))
;;;       (int32 1)
;;;       (int32 0)))

;;; (define (Spec1 x y)
;;; (bvadd x y))

;;; (define sol
;;;     (synthesize
;;;      #:forall    (list l h)
;;;      #:guarantee (assert (equal? (impl-fast l h) (Spec l h)))))
;;; sol
;;; (print-forms sol)

;;; (define sol
;;;     (synthesize
;;;      #:forall    (list l h)
;;;      #:guarantee (assert (equal? (bvmid-fast l h) (Spec1 l h)))))
;;; sol
;;; (print-forms sol)


(define-grammar (Impl_grammar x y)
  [expr
   (choose
    (if (and (equal? (expr) (expr)) (equal? (expr) (expr))) (expr) (expr))
    (bvadd (expr) (expr))
    (bvsub (expr) (expr))
    x
    y
    (?? int32?))]
  )

(define (impl-fast lo hi)
  (Impl_grammar lo hi #:depth 2))

(define (Spec x y)
  (if (and (equal? x (int32 22)) (equal? y (int32 10)))
      (int32 1)
      (int32 0)))

(define sol
    (synthesize
     #:forall    (list l h)
     #:guarantee (assert (equal? (impl-fast l h) (Spec l h)))))
sol
(print-forms sol)