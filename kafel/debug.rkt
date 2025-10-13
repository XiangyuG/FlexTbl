#lang rosette/safe

(require rosette/lib/synthax)
(require rosette/base/base)
(require rosette/solver/smt/z3)

;; --- symbolic inputs ---
(define-symbolic x (bitvector 4))
(define-symbolic y (bitvector 1))
(define-symbolic z (bitvector 8))

;; --- define symbolic costs ---
(define-symbolic cost1 cost2 cost3 integer?)
(assert (and (>= cost1 0) (= cost2 0) (= cost3 0)))

;; --- define implementation (no grammar) ---
(define (impl x y z)
  (let* (
        ;;; [a (choose (bv 0 1) (bv 1 1))]            ; choose #1
        ;;; ;;;  [_ (if (bveq a (bv 0 1)) (assert (= cost1 0)) (assert (= cost1 1)))]
         
        ;;;  [b (choose (bvand x (bv 0 4))
        ;;;             (bvor x (bv 1 4)))]            ; choose #2
        ;;;  [_ (if (equal? b (bvand x (bv 0 4)))
        ;;;         (assert (= cost2 0))
        ;;;         (assert (= cost2 0)))]
         
        ;;;  [c (choose (bveq y (bv 0 1))
        ;;;             (bveq z (bv 0 8)))]            ; choose #3
        ;;;  [_ (if (equal? c (bveq y (bv 0 1)))
        ;;;         (assert (= cost3 0))
        ;;;         (assert (= cost3 0)))]
         [cond-expr0 ((choose bveq bvslt) 
         (choose x y z ((choose bvand bvor) (choose x y z (bv 0 4) (bv 1 4) (bv 2 4) (bv 0 1) (bv 1 1) (bv 0 8)) (choose x y z (bv 0 4) (bv 1 4) (bv 2 4) (bv 0 1) (bv 1 1) (bv 0 8))))
         (choose (bv 0 4) (bv 1 4) (bv 2 4) (bv 0 1) (bv 1 1) (bv 0 8)))]
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
         [_ (if (or (= choiceexpr0 0) (= choiceexpr0 1)) (assert (= cost1 0)) (assert (= cost1 1)))]
         )
    ;; final output
    expr0))

;; total cost = sum of all symbolic costs
(define total-cost (+ cost1 cost2 cost3))

;; --- define spec ---
(define (spec x y z) (bv 0 1))

;; --- optimize to minimize total cost ---
(define sol
   (synthesize
     #:forall    (list x y z)
     #:guarantee (begin
    ;;;   (assume (or (equal? proto_sym (int32 0)) (equal? proto_sym (int32 1))))
      (assert (and (bveq (impl x y z) (spec x y z)) (= total-cost 0)))
    ))
)

(print-forms sol)
