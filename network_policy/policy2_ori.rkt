#lang rosette/safe

(require rosette/lib/synthax)
(require rosette/base/base)

(define-symbolic ip (bitvector 32))

(define (bvne a b) (not (bveq a b)))

(define int32? (bitvector 32))

(define (spec ip)
  (cond
    [(bvne (bvand ip (bv #xFF000000 32)) (bv #x0A000000 32)) (bv 1 1)] ;; DROP
    [(and (bveq (bvand ip (bv #xFF000000 32)) (bv #x0A000000 32)) (bveq (bvand ip (bv #xFFFFFF00 32)) (bv #x0A010100 32))) (bv 1 1)] ;; DROP
    [else               (bv 0 1)]))   ;; ACCEPT

(define (impl ip)
  (let* (
         [cond-expr0 ((choose bveq bvult bvugt bvule bvuge bvne) 
         (choose ip ((choose bvand bvor) (choose ip (?? int32?)) (choose ip (?? int32?))) )
         (choose (?? int32?) ip ))]

         [cond-expr0L ((choose bveq bvult bvugt bvule bvuge bvne) 
         (choose ip ((choose bvand bvor) (choose ip (?? int32?)) (choose ip (?? int32?))) )
         (choose (?? int32?) ip ))]

         [cond-expr0R ((choose bveq bvult bvugt bvule bvuge bvne) 
         (choose ip ((choose bvand bvor) (choose ip (?? int32?)) (choose ip (?? int32?))) )
         (choose (?? int32?) ip ))]

         [cond-expr0LL ((choose bveq bvult bvugt bvule bvuge bvne) 
         (choose ip ((choose bvand bvor) (choose ip (?? int32?)) (choose ip (?? int32?))) )
         (choose (?? int32?) ip ))]

         [cond-expr0LR ((choose bveq bvult bvugt bvule bvuge bvne) 
         (choose ip ((choose bvand bvor) (choose ip (?? int32?)) (choose ip (?? int32?))) )
         (choose (?? int32?) ip ))]

         [cond-expr0RL ((choose bveq bvult bvugt bvule bvuge bvne) 
         (choose ip ((choose bvand bvor) (choose ip (?? int32?)) (choose ip (?? int32?))) )
         (choose (?? int32?) ip ))]

         [cond-expr0RR ((choose bveq bvult bvugt bvule bvuge bvne) 
         (choose ip ((choose bvand bvor) (choose ip (?? int32?)) (choose ip (?? int32?))) )
         (choose (?? int32?) ip ))]
         
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

        ;;;  [choiceexpr0L (choose 0 1 2)]
        ;;;   [expr0L (cond
        ;;;       [(= choiceexpr0L 0) (bv 0 1)]  ;;; ALLOW
        ;;;       [(= choiceexpr0L 1) (bv 1 1)]  ;;; KILL
        ;;;       [else (if cond-expr0L expr0LL expr0LR)]
        ;;;       )
        ;;;   ]
        ;;; [_ (if (or (= choiceexpr0L 0) (= choiceexpr0L 1)) (assert (= cost0L 0)) (assert (= cost0L 1)))]

        ;;;  [choiceexpr0R (choose 0 1 2)]
        ;;;  [expr0R (cond
        ;;;     [(= choiceexpr0R 0) (bv 0 1)]  ;;; ALLOW
        ;;;     [(= choiceexpr0R 1) (bv 1 1)]  ;;; KILL
        ;;;     [else (if cond-expr0R expr0RL expr0RR)]
        ;;;     )
        ;;;  ] 
        ;;;  [_ (if (or (= choiceexpr0R 0) (= choiceexpr0R 1)) (assert (= cost0R 0)) (assert (= cost0R 1)))]
            [expr0LL (if cond-expr0LL expr0LLL expr0LLR)]
         [expr0LR (if cond-expr0LR expr0LRL expr0LRR)]
           [expr0RL (if cond-expr0RL expr0RLL expr0RLR)]
         [expr0RR (if cond-expr0RR expr0RRL expr0RRR)]
          [expr0L (if cond-expr0L expr0LL expr0LR)]
         [expr0R (if cond-expr0R expr0RL expr0RR)]
         [expr0 (if cond-expr0 expr0L expr0R)]
         
         )
    expr0)
)


;; --- optimize to minimize total cost ---
(define sol
   (synthesize
     #:forall    (list ip)
     #:guarantee (begin
      (assert (and (bveq (impl ip) (spec ip))))
    ))
)

(print-forms sol)