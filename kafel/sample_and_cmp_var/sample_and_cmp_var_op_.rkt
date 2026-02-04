#lang rosette/safe

(require rosette/lib/synthax)
(require rosette/base/base)

(define-symbolic bufhi (bitvector 32))
(define-symbolic buflo (bitvector 32))
(define-symbolic fdhi (bitvector 32))
(define-symbolic fdlo (bitvector 32))

(define-symbolic cost0 cost0L cost0R cost0LL cost0LR cost0RL cost0RR integer?)
(assert (and (>= cost0 0) (>= cost0L 0) (>= cost0R 0)
             (>= cost0LL 0) (>= cost0LR 0) (>= cost0RL 0) (>= cost0RR 0)))

(define (spec bufhi buflo fdhi fdlo)
  (cond
    [(bvult (bvand bufhi fdhi) (bv 3261509415 32)) (bv 0 1)] ;; ALLOW
    [(and (bveq (bvand bufhi fdhi) (bv 3261509415 32)) (bvule (bvand buflo fdlo) (bv 2362810165  32))) (bv 0 1)] ;; ALLOW
    [else               (bv 1 1)]))   ;; KILL

(define (impl bufhi buflo fdhi fdlo)
  (let* (
         [cond-expr0 ((choose bveq bvult bvugt bvule bvuge (not bveq)) 
         (choose bufhi buflo fdhi fdlo ((choose bvand bvor) (choose bufhi buflo fdhi fdlo) (choose bufhi buflo fdhi fdlo)))
         (choose (bv 3261509415 32) (bv 2362810165 32) bufhi buflo fdhi fdlo))]

         [cond-expr0L ((choose bveq bvult bvugt bvule bvuge (not bveq)) 
         (choose bufhi buflo fdhi fdlo ((choose bvand bvor) (choose bufhi buflo fdhi fdlo) (choose bufhi buflo fdhi fdlo)))
         (choose (bv 3261509415 32) (bv 2362810165  32) bufhi buflo fdhi fdlo))]

         [cond-expr0R ((choose bveq bvult bvugt bvule bvuge (not bveq)) 
         (choose bufhi buflo fdhi fdlo ((choose bvand bvor) (choose bufhi buflo fdhi fdlo) (choose bufhi buflo fdhi fdlo)))
         (choose (bv 3261509415 32) (bv 2362810165  32) bufhi buflo fdhi fdlo))]

         [cond-expr0LL ((choose bveq bvult bvugt bvule bvuge (not bveq)) 
         (choose bufhi buflo fdhi fdlo ((choose bvand bvor) (choose bufhi buflo fdhi fdlo) (choose bufhi buflo fdhi fdlo)))
         (choose (bv 3261509415 32) (bv 2362810165  32) bufhi buflo fdhi fdlo))]

         [cond-expr0LR ((choose bveq bvult bvugt bvule bvuge (not bveq)) 
         (choose bufhi buflo fdhi fdlo ((choose bvand bvor) (choose bufhi buflo fdhi fdlo) (choose bufhi buflo fdhi fdlo)))
         (choose (bv 3261509415 32) (bv 2362810165  32) bufhi buflo fdhi fdlo))]

         [cond-expr0RL ((choose bveq bvult bvugt bvule bvuge (not bveq)) 
         (choose bufhi buflo fdhi fdlo ((choose bvand bvor) (choose bufhi buflo fdhi fdlo) (choose bufhi buflo fdhi fdlo)))
         (choose (bv 3261509415 32) (bv 2362810165  32) bufhi buflo fdhi fdlo))]

         [cond-expr0RR ((choose bveq bvult bvugt bvule bvuge (not bveq)) 
         (choose bufhi buflo fdhi fdlo ((choose bvand bvor) (choose bufhi buflo fdhi fdlo) (choose bufhi buflo fdhi fdlo)))
         (choose (bv 3261509415 32) (bv 2362810165  32) bufhi buflo fdhi fdlo))]
         
         [expr0LLL (choose (bv 0 1)  ;;; ALLOW
                          (bv 1 1)  ;;; KILL
                          )
         ]
         [expr0LLR (choose (bv 0 1)  ;;; ALLOW
                          (bv 1 1)  ;;; KILL
                          )
         ]
         [expr0LRL (choose (bv 0 1)  ;;; ALLOW
                          (bv 1 1)  ;;; KILL
                          )
         ]
         [expr0LRR (choose (bv 0 1)  ;;; ALLOW
                          (bv 1 1)  ;;; KILL
                          )
         ]
         [expr0RLL (choose (bv 0 1)  ;;; ALLOW
                          (bv 1 1)  ;;; KILL
                          )
         ]
         [expr0RLR (choose (bv 0 1)  ;;; ALLOW
                          (bv 1 1)  ;;; KILL
                          )
         ]
         [expr0RRL (choose (bv 0 1)  ;;; ALLOW
                          (bv 1 1)  ;;; KILL
                          )
         ]
         [expr0RRR (choose (bv 0 1)  ;;; ALLOW
                          (bv 1 1)  ;;; KILL
                          )
         ]
        [choiceexpr0LL (choose 0 1 2)]
          [expr0LL (cond
              [(= choiceexpr0LL 0) (bv 0 1)]  ;;; ALLOW
              [(= choiceexpr0LL 1) (bv 1 1)]  ;;; KILL
              [else (if cond-expr0LL expr0LLL expr0LLR)]
              )
          ]
        [_ (if (or (= choiceexpr0LL 0) (= choiceexpr0LL 1)) (assert (= cost0LL 0)) (assert (= cost0LL 1)))]

        [choiceexpr0LR (choose 0 1 2)]
          [expr0LR (cond
              [(= choiceexpr0LR 0) (bv 0 1)]  ;;; ALLOW
              [(= choiceexpr0LR 1) (bv 1 1)]  ;;; KILL
              [else (if cond-expr0LR expr0LRL expr0LRR)]
              )
          ]
        [_ (if (or (= choiceexpr0LR 0) (= choiceexpr0LR 1)) (assert (= cost0LR 0)) (assert (= cost0LR 1)))]

        [choiceexpr0RL (choose 0 1 2)]
          [expr0RL (cond
              [(= choiceexpr0RL 0) (bv 0 1)]  ;;; ALLOW
              [(= choiceexpr0RL 1) (bv 1 1)]  ;;; KILL
              [else (if cond-expr0RL expr0RLL expr0RLR)]
              )
          ]
        [_ (if (or (= choiceexpr0RL 0) (= choiceexpr0RL 1)) (assert (= cost0RL 0)) (assert (= cost0RL 1)))]

        [choiceexpr0RR (choose 0 1 2)]
          [expr0RR (cond
              [(= choiceexpr0RR 0) (bv 0 1)]  ;;; ALLOW
              [(= choiceexpr0RR 1) (bv 1 1)]  ;;; KILL
              [else (if cond-expr0RR expr0RRL expr0RRR)]
              )
          ]
        [_ (if (or (= choiceexpr0RR 0) (= choiceexpr0RR 1)) (assert (= cost0RR 0)) (assert (= cost0RR 1)))]

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

(define total-cost (+ cost0 cost0L cost0R cost0LL cost0LR cost0RL cost0RR))

;; --- optimize to minimize total cost ---
(define sol
   (synthesize
     #:forall    (list bufhi buflo fdhi fdlo)
     #:guarantee (begin
      (assert (and (bveq (impl bufhi buflo fdhi fdlo) (spec bufhi buflo fdhi fdlo)) (= total-cost 3)))
    ))
)

(print-forms sol)