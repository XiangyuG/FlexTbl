#lang rosette/safe

(require rosette/lib/synthax)
(require rosette/base/base)

(define-symbolic buflo (bitvector 32))

(define-symbolic cost0 cost0L cost0R integer?)
(assert (and (>= cost0 0)))

(define (spec buflo)
  (cond
    [(bveq (bvand buflo (bv 214 32)) (bv 214 32)) (bv 0 1)] ;; ALLOW
    [else               (bv 1 1)]))   ;; KILL

(define (impl buflo)
  (let* (
         [cond-expr0 ((choose bveq bvult bvugt bvule bvuge (not bveq)) 
         (choose buflo ((choose bvand bvor) (choose buflo ) (choose buflo (bv 214 32))) )
         (choose (bv 214 32) buflo ))]
         
         [expr0L (choose (bv 0 1)  ;;; ALLOW
                          (bv 1 1)  ;;; KILL
                          )
         ]
         [expr0R (choose (bv 0 1)  ;;; ALLOW
                          (bv 1 1)  ;;; KILL
                          )
         ]

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
     #:forall    (list buflo)
     #:guarantee (begin
      (assert (and (bveq (impl buflo) (spec buflo)) (= total-cost 1)))
    ))
)

(print-forms sol)