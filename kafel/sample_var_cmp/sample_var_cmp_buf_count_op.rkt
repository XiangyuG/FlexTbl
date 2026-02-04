#lang rosette/safe

(require rosette/lib/synthax)
(require rosette/base/base)

(define-symbolic bufhi (bitvector 32))
(define-symbolic buflo (bitvector 32))
(define-symbolic counthi (bitvector 32))
(define-symbolic countlo (bitvector 32))

(define (bvne a b) (not (bveq a b)))

(define-symbolic cost0 cost0L cost0R integer?)
(assert (and (>= cost0 0) (>= cost0L 0) (>= cost0R 0)))

(define (spec bufhi buflo counthi countlo)
  (cond
    [(and (bveq bufhi counthi) (bveq buflo countlo)) (bv 0 1)] ;; ALLOW
    [else               (bv 1 1)]))   ;; KILL

(define (impl bufhi buflo counthi countlo)
  (let* (
         [cond-expr0 ((choose bveq bvult bvugt bvule bvuge (not bveq)) 
         (choose bufhi buflo counthi countlo ((choose bvand bvor) (choose bufhi buflo counthi countlo) (choose bufhi buflo counthi countlo)))
         (choose (bv 3261509415 32) (bv 2362810165 32) bufhi buflo counthi countlo))]
         [cond-expr0L ((choose bveq bvult bvugt bvule bvuge (not bveq)) 
         (choose bufhi buflo counthi countlo ((choose bvand bvor) (choose bufhi buflo counthi countlo) (choose bufhi buflo counthi countlo)))
         (choose (bv 3261509415 32) (bv 2362810165  32) bufhi buflo counthi countlo))]

         [cond-expr0R ((choose bveq bvult bvugt bvule bvuge (not bveq)) 
         (choose bufhi buflo counthi countlo ((choose bvand bvor) (choose bufhi buflo counthi countlo) (choose bufhi buflo counthi countlo)))
         (choose (bv 3261509415 32) (bv 2362810165  32) bufhi buflo counthi countlo))]
         
         [expr0LL (choose (bv 0 1)  ;;; ALLOW
                          (bv 1 1)  ;;; KILL
                          )
         ]
         [expr0LR (choose (bv 0 1)  ;;; ALLOW
                          (bv 1 1)  ;;; KILL
                          )
         ]
         [expr0RL (choose (bv 0 1)  ;;; ALLOW
                          (bv 1 1)  ;;; KILL
                          )
         ]
         [expr0RR (choose (bv 0 1)  ;;; ALLOW
                          (bv 1 1)  ;;; KILL
                          )
         ]

         [choiceexpr0L (choose 0 1 2)]
          [expr0L (cond
              [(= choiceexpr0L 0) (bv 0 1)]  ;;; ALLOW
              [(= choiceexpr0L 1) (bv 1 1)]  ;;; KILL
              [else (if cond-expr0L expr0LL expr0LR)]
              )
          ]
        [_ (if (or (= choiceexpr0L 0) (= choiceexpr0L 1)) (assert (= cost0L 0)) (assert (= cost0L 1)))]

         [choiceexpr0R (choose 0 1 2)]
         [expr0R (cond
            [(= choiceexpr0R 0) (bv 0 1)]  ;;; ALLOW
            [(= choiceexpr0R 1) (bv 1 1)]  ;;; KILL
            [else (if cond-expr0R expr0RL expr0RR)]
            )
         ] 
         [_ (if (or (= choiceexpr0R 0) (= choiceexpr0R 1)) (assert (= cost0R 0)) (assert (= cost0R 1)))]

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

(define total-cost (+ cost0 cost0L cost0R))

;; --- optimize to minimize total cost ---
(define sol
   (synthesize
     #:forall    (list bufhi buflo counthi countlo)
     #:guarantee (begin
      (assert (and (bveq (impl bufhi buflo counthi countlo) (spec bufhi buflo counthi countlo)) (= total-cost 2)))
    ))
)

(print-forms sol)