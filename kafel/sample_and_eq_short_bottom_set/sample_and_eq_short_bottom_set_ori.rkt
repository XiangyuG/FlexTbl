#lang rosette/safe

(require rosette/lib/synthax)
(require rosette/base/base)

(define-symbolic buf (bitvector 32))

(define int32? (bitvector 32))

(define-symbolic cost0 integer?)
(assert (and (>= cost0 0)))

(define (spec buf)
  (cond
    [(and (bveq (bvand buf (bv #xf1 32)) (bv 0 32))) (bv 0 1)] ;; ALLOW
    [else               (bv 1 1)]))   ;; KILL

(define (impl buf)
  (let* (
         [cond-expr0 ((choose bveq bvult bvugt bvule bvuge (not bveq)) 
         (choose buf ((choose bvand bvor) (choose buf (?? int32?)) (choose buf (?? int32?))) )
         (choose (?? int32?) buf ))]
         
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
     #:forall    (list buf)
     #:guarantee (begin
      (assert (and (bveq (impl buf) (spec buf))))
    ))
)

(print-forms sol)