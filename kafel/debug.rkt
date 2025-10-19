#lang rosette/safe

(require rosette/lib/synthax)
(require rosette/base/base)
(require rosette/solver/smt/z3)

;; --- symbolic inputs ---
(define-symbolic x (bitvector 4))
(define-symbolic y (bitvector 1))
(define-symbolic z (bitvector 8))

;; --- define symbolic costs ---
(define-symbolic cost0 cost0L cost0R integer?)
(assert (and (>= cost0 0) (>= cost0L 0) (>= cost0R 0)))

;; --- define implementation (no grammar) ---
(define (impl x y z)
  (let* (
         [cond-expr0 ((choose bveq bvslt) 
         (choose x y z ((choose bvand bvor) (choose x y z (bv 0 4) (bv 1 4) (bv 2 4) (bv 0 1) (bv 1 1) (bv 0 8)) (choose x y z (bv 0 4) (bv 1 4) (bv 2 4) (bv 0 1) (bv 1 1) (bv 0 8))))
         (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 0 1) (bv 1 1) (bv 0 8)))]
         [cond-expr0L ((choose bveq bvslt) 
         (choose x y z ((choose bvand bvor) (choose x y z (bv 0 4) (bv 1 4) (bv 2 4) (bv 0 1) (bv 1 1) (bv 0 8)) (choose x y z (bv 0 4) (bv 1 4) (bv 2 4) (bv 0 1) (bv 1 1) (bv 0 8))))
         (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 0 1) (bv 1 1) (bv 0 8)))]
         [cond-expr0R ((choose bveq bvslt) 
         (choose x y z ((choose bvand bvor) (choose x y z (bv 0 4) (bv 1 4) (bv 2 4) (bv 0 1) (bv 1 1) (bv 0 8)) (choose x y z (bv 0 4) (bv 1 4) (bv 2 4) (bv 0 1) (bv 1 1) (bv 0 8))))
         (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 0 1) (bv 1 1) (bv 0 8)))]
         
         [expr0LL (choose (bv 0 1)  ;;; ALLOW
                          (bv 1 1)  ;;; KILL
                          )
         ]
         [expr0LR (choose (bv 0 1)  ;;; ALLOW
                          (bv 1 1)  ;;; KILL
                          ) ]
         [expr0RL (choose (bv 0 1)  ;;; ALLOW
                          (bv 1 1)  ;;; KILL
                          )
         ]
         [expr0RR (choose (bv 0 1)  ;;; ALLOW
                          (bv 1 1)  ;;; KILL
                          ) ]
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
    ;; final output
    expr0))

;; total cost = sum of all symbolic costs
(define total-cost (+ cost0 cost0L cost0R))

;; --- define spec ---
(define (spec x y z)
  (cond
    ;;; [(and (bveq x (bv 0 4)) (bveq y (bv 0 1)) (bveq z (bv 0 8))) (bv 0 1)] ;; ALLOW
    ;;; [(bveq x (bv 0 4)) (bv 0 1)] ;; ALLOW 1 condition
    [(and (bveq x (bv 0 4)) (bveq y (bv 0 1))) (bv 0 1)] ;; ALLOW
    [else               (bv 1 1)]))   ;; KILL

;; --- optimize to minimize total cost ---
(define sol
   (synthesize
     #:forall    (list x y z)
     #:guarantee (begin
    ;;;   (assume (or (equal? proto_sym (int32 0)) (equal? proto_sym (int32 1))))
      (assert (and (bveq (impl x y z) (spec x y z)) (= total-cost 3)))
    ))
)

(print-forms sol)
