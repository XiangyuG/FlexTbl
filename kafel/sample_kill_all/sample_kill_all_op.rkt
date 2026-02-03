#lang rosette/safe

(require rosette/lib/synthax)
(require rosette/base/base)

(define-symbolic x (bitvector 32))

(define-symbolic cost0 integer?)
(assert (>= cost0 0))

(define (spec x)
  (cond
    [(or (bveq x (bv 0 32)) (bveq x (bv 1 32)) (bveq x (bv 2 32)) (bveq x (bv 8 32))) (bv 1 1)] ;; KILL
    [else               (bv 1 1)]))   ;; KILL

(define (impl x)
  (let* (
         [cond-expr0 ((choose bveq bvult bvugt (not bveq)) 
         (choose x ((choose bvand bvor) (choose x (bv 0 32) (bv 1 32) (bv 2 32) (bv 8 32))))
         (choose (bv 0 32) (bv 1 32) (bv 2 32) (bv 8 32)))]
         
         [expr0L (choose (bv 0 1)  ;;; ALLOW
                          (bv 1 1)  ;;; KILL
                          )]
         [expr0R (choose (bv 0 1)  ;;; ALLOW
                          (bv 1 1)  ;;; KILL
                          )]
         [choiceexpr0 (choose 0 1 2)]
         [expr0 (cond
            [(= choiceexpr0 0) (bv 0 1)]  ;;; ALLOW
            [(= choiceexpr0 1) (bv 1 1)]  ;;; KILL
            [else (if cond-expr0 expr0L expr0R)]
            )
         ]
         [_ (if (or (= choiceexpr0 0) (= choiceexpr0 1)) (assert (= cost0 0)) (assert (= cost0 1)))]
         )
    expr0)
)

(define total-cost cost0)

;; --- optimize to minimize total cost ---
(define sol
   (synthesize
     #:forall    (list x)
     #:guarantee (begin
      (assert (and (bveq (impl x) (spec x)) (= total-cost 0)))
    ))
)

(print-forms sol)