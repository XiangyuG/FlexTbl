#lang rosette/safe

(require rosette/lib/synthax)
(require rosette/base/base)

(define-symbolic buflo (bitvector 32))
(define-symbolic bufhi (bitvector 32))

(define int32? (bitvector 32))

(define-symbolic cost0 cost0L cost0R integer?)
(assert (and (>= cost0 0)))

(define (spec buflo bufhi)
  (cond
    [(bveq (bvand bufhi (bv #xf1f1f1f1 32)) (bv 0 32)) (bv 0 1)] ;; ALLOW
    [else               (bv 1 1)]))   ;; KILL

(define (impl buflo bufhi)
  (let* (
         [cond-expr0 ((choose bveq bvult bvugt bvule bvuge (not bveq)) 
         (choose buflo bufhi ((choose bvand bvor) (choose buflo bufhi (?? int32?)) (choose buflo bufhi (?? int32?))) )
         (choose (?? int32?) buflo bufhi))]
         
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
     #:forall    (list buflo bufhi)
     #:guarantee (begin
      (assert (and (bveq (impl buflo bufhi) (spec buflo bufhi))))
    ))
)

(print-forms sol)