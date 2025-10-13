#lang rosette/safe

(require rosette/lib/synthax)
(require rosette/base/base)



(define-symbolic x (bitvector 4))
(define-symbolic y (bitvector 1))
(define-symbolic z (bitvector 8))


;; Spec
(define (f x y z)
  (cond
    [(and (bveq x (bv 0 4)) (bveq y (bv 0 1)) (bveq z (bv 0 8))) (bv 0 1)] ;; ALLOW
    ;;; [(bveq x (bv 0 4)) (bv 0 1)] ;; ALLOW 1 condition
    ;;; [(and (bveq x (bv 0 4)) (bveq y (bv 0 1))) (bv 0 1)] ;; ALLOW
    [else               (bv 1 1)]))   ;; KILL



(displayln (f (bv 0 4) (bv 0 1) (bv 0 8)))   ; Should output (bv 0 1)
(displayln (f (bv 1 4) (bv 0 1) (bv 0 8)))   ; Should output (bv 1 1)

(define-grammar (Impl_grammar x y z)
  [expr
   (choose
    (bv 0 1)  ;;; ALLOW
    (bv 1 1)  ;;; KILL
    (if (cond-expr) (expr) (expr))
    )]
  [cmp
    (choose bveq bvslt)
  ]
  [op
    (choose 
    x
    y
    z
    ((choose bvand bvor) (choose x y z (bv 0 4) (bv 1 4) (bv 2 4) (bv 0 1) (bv 1 1) (bv 0 8)) 
                                    (choose x y z (bv 0 4) (bv 1 4) (bv 2 4) (bv 0 1) (bv 1 1) (bv 0 8)))
    )
  ]
  [cond-expr
    (choose
    ((cmp) (op) (choose (bv 0 4) (bv 1 4) (bv 2 4)))
    ((cmp) (op) (choose (bv 0 1) (bv 1 1)))
    ((cmp) (op) (bv 0 8)))
  ]
)

;; --- top-level function ---
(define (g x y z)
  (Impl_grammar x y z #:depth 4)  ; x nested levels of if-then-else
)

(define sol
    (synthesize
     #:forall    (list x y z)
     #:guarantee (begin
    ;;;   (assume (or (equal? proto_sym (int32 0)) (equal? proto_sym (int32 1))))
      (assert (bveq (f x y z) 
                     (g x y z)))
    ))
)

(print-forms sol)