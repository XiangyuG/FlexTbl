#lang rosette/safe

(require rosette/lib/synthax)
(require rosette/base/base)

(define-symbolic ip (bitvector 32))

(define (bvne a b) (not (bveq a b)))
(define-symbolic cost0 cost0L cost0R integer?)
(assert (and (>= cost0 0) (>= cost0L 0) (>= cost0R 0)))

(define (spec ip)
  (cond
    [(bvne (bvand ip (bv #xFFF00000 32)) (bv #xAC100000 32)) (bv 1 1)] ;; DROP
    [(and (bveq (bvand ip (bv #xFFF00000 32)) (bv #xAC100000 32)) (bveq (bvand ip (bv #xFFFFFF00 32)) (bv #xAC110400 32))) (bv 1 1)] ;; DROP
    [else               (bv 0 1)]))   ;; ACCEPT

(define (impl ip)
  (let* (
         [cond-expr0 ((choose bveq bvult bvugt bvule bvuge bvne) 
         (choose ip ((choose bvand bvor) (choose ip (bv #xFFF00000 32) (bv #xFFFFFF00 32) (bv #xAC100000 32) (bv #xAC110400 32)) (choose ip (bv #xFFF00000 32) (bv #xFFFFFF00 32) (bv #xAC100000 32) (bv #xAC110400 32))) )
         (choose (bv #xFFF00000 32) (bv #xFFFFFF00 32) (bv #xAC110400 32) (bv #xAC100000 32) ip ))]
        
          [cond-expr0L ((choose bveq bvult bvugt bvule bvuge bvne) 
         (choose ip ((choose bvand bvor) (choose ip (bv #xFFF00000 32) (bv #xFFFFFF00 32) (bv #xAC100000 32) (bv #xAC110400 32)) (choose ip (bv #xFFF00000 32) (bv #xFFFFFF00 32) (bv #xAC100000 32) (bv #xAC110400 32))) )
         (choose (bv #xFFF00000 32) (bv #xFFFFFF00 32) (bv #xAC110400 32) (bv #xAC100000 32) ip ))]

         [cond-expr0R ((choose bveq bvult bvugt bvule bvuge bvne) 
         (choose ip ((choose bvand bvor) (choose ip (bv #xFFF00000 32) (bv #xFFFFFF00 32) (bv #xAC100000 32) (bv #xAC110400 32)) (choose ip (bv #xFFF00000 32) (bv #xFFFFFF00 32) (bv #xAC100000 32) (bv #xAC110400 32))) )
         (choose (bv #xFFF00000 32) (bv #xFFFFFF00 32) (bv #xAC110400 32) (bv #xAC100000 32) ip ))]

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

(define total-cost (+ cost0 cost0R cost0L))

;; --- optimize to minimize total cost ---
(define sol
   (synthesize
     #:forall    (list ip)
     #:guarantee (begin
      (assert (and (bveq (impl ip) (spec ip)) (= total-cost 2)))
    ))
)

(print-forms sol)