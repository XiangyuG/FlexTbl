#lang rosette

(require rosette/lib/synthax)     ; Require the sketching library.

(define int32? (bitvector 32))
(define (int32 i)
  (bv i int32?))

;;  ------------------ Define program using our DSL
(define rules
  '((tcp 22 ACCEPT)
    ;;; (udp 22 ACCEPT)
  ))

;; tcp -> 1; udp -> 0
(define (proto->int proto)
  (cond [(equal? proto 'tcp) (int32 1)]
        [(equal? proto 'udp) (int32 0)]
        [else (error "Unknown proto")]))


;; ACCEPT -> 1; DROP -> 0
(define (action->int act)
  (cond [(equal? act 'ACCEPT) (int32 1)]
        [(equal? act 'DROP) (int32 0)]
        [else (error "Unknown action")]))

;; Generate Spec based on DSL program
(define (generate-spec rules)
  (lambda (x y)
    (let loop ([rules rules])
      (cond
        [(null? rules) (int32 0)] ; default: drop
        [else
         (define r (car rules))
         (define proto (proto->int (first r)))
         (define port  (int32 (second r)))
         (define act   (action->int (third r)))
         (if (and (equal? x proto) (equal? y port))
             act
             (loop (cdr rules)))]))))

(define Spec (generate-spec rules))

(define-symbolic proto port int32?)


(define-grammar (Impl_grammar x y)
  [expr
   (choose
    (if (cond-expr) (expr) (expr))
    (?? int32?))]

  [cond-expr
   (choose
    (equal? (vexpr) (vexpr))
    (and (cond-expr) (cond-expr))
    (or (cond-expr) (cond-expr))
    (not (cond-expr)))]
  [vexpr
   (choose
    x
    y
    (?? int32?))]     
  )
  

(define (impl-fast lo hi)
  (Impl_grammar lo hi #:depth 3))


(define sol
    (synthesize
     #:forall    (list proto port)
     #:guarantee (begin
      (assume (or (equal? proto (int32 0)) (equal? proto (int32 1))))
      (assert (equal? (impl-fast proto port) (Spec proto port))))
    )
)

(define sol-str
  (with-output-to-string
    (lambda () (print-forms sol))))

(displayln sol-str)