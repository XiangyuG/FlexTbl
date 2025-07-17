#lang rosette

(require rosette/lib/synthax)

; Our DSL
(define rules
  '((tcp 22 ACCEPT)
    (udp 53 ACCEPT)
  ))

;; tcp -> 1; udp -> 0
(define (proto->int proto)
  (cond [(equal? proto 'tcp) 1]
        [(equal? proto 'udp) 0]
        [else (error "Unknown proto")]))


;; ACCEPT -> 1; DROP -> 0
(define (action->int act)
  (cond [(equal? act 'ACCEPT) 1]
        [(equal? act 'DROP) 0]
        [else (error "Unknown action")]))

;; Generate Spec based on DSL program
(define (generate-spec rules)
  (lambda (x y)
    (let loop ([rules rules])
      (cond
        [(null? rules) 0] ; default: drop
        [else
         (define r (car rules))
         (define proto (proto->int (first r)))
         (define port  (second r))
         (define act   (action->int (third r)))
         (if (and (= x proto) (= y port))
             act
             (loop (cdr rules)))]))))

(define Spec (generate-spec rules))

; Synthesizing
(define-symbolic x y integer?)

(define-symbolic x_match integer?)
(define-symbolic y_match integer?)
(define (Impl x y)
  (if (and (= x x_match)
           (= y y_match))
      1
      0))

(define spec_result (Spec x y))
(define impl_result (Impl x y))



;;; (define sol
;;;   (synthesize
;;;    #:forall (list x y)
;;;    #:guarantee
;;;    (assert (equal? spec_result impl_result))))

;;; (define x_val (evaluate x_match sol))
;;; (define y_val (evaluate y_match sol))

;;; ;; Code generation
;;; (define result-code
;;;   (format "if (x == ~a && y == ~a) return 1; else return 0;" x_val y_val))

;;; (displayln result-code)


(define-grammar (Impl_grammar x y)
  [expr
   (choose
    (if (bexpr) (expr) (expr))
    x
    y
    (?? integer?))]
  [bexpr
   (choose
    (= (expr) (expr))
    (and (bexpr) (bexpr))
    (or (bexpr) (bexpr)))])

(define solution
  (synthesize
   #:forall (list x y)
   #:guarantee (= (Spec x y) (Impl_grammar x y))))

(define impl-evaluated
  (evaluate (Impl_grammar x y) solution))

(displayln impl-evaluated)
