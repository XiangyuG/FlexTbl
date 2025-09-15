#lang rosette/safe
(require rosette/lib/synthax)     ; Require the sketching library.


;;; Example 1: Synthesis with restricted constant set
;;; (define int32? (bitvector 32))

;;; ;; Restricted constant set
;;; (define-grammar (const32)
;;;   [cst (choose (bv 0 32) (bv 1 32) (bv 42 32))])

;;; ;; Define expression grammar over one input x
;;; (define-grammar (expr x)
;;;   [e (choose
;;;       x                       ; just the input
;;;       (const32)               ; a constant from the set
;;;       (bvadd x (const32))     ; x + const
;;;       (bvsub x (const32))     ; x - const
;;;       )])

;;; ;; Example candidate function
;;; (define (f x) (expr x #:depth 2))

;;; (define-symbolic x (bitvector 32))

;;; ;; Run synthesis
;;; (define sol
;;;   (synthesize
;;;    #:forall (list x)
;;;    #:guarantee (assert (equal? (f x) (bvadd x (bv 1 32))))
;;;    ))

;;; (print-forms sol)


;;; Example 2: speed up effect from constant synthesis algorithm

;;; (define int32? (bitvector 32))
;;; (define-grammar (const32)
;;;   [cst (choose (bv 0 32) (bv 1 32) (bv 42 32))])

;;; (define-symbolic x (bitvector 32))

;;; (define-grammar (expr x)
;;;   [e (choose x (const32) (bvadd x (const32)))])

;;; (define (f x) (expr x #:depth 1))

;;; (define sol2
;;;     (synthesize
;;;     #:forall (list x)
;;;     #:guarantee (assert (equal? (f x) (bvadd x (bv 1 32)))))
;;; )

;;; (print-forms sol2)



;;; Example 3: simple synthesis
(define-symbolic proto (bitvector 8))
(define-symbolic srcIP (bitvector 32))
(define-symbolic dstIP (bitvector 32))
(define-symbolic srcPort (bitvector 16))
(define-symbolic dstPort (bitvector 16))

(define (spec0 proto srcIP dstIP srcPort dstPort)
  (if (and (bveq proto (bv 0 8)) (bveq srcIP (bv 1 32)) (bveq dstIP (bv 0 32)) (bveq srcPort (bv 0 16)) (bveq dstPort (bv 0 16))) (bv 1 8) (bv 0 8)))

(define (spec1 proto srcIP dstIP srcPort dstPort)
  (if (and (bveq proto (bv 0 8)) (bveq srcIP (bv 0 32)) (bveq dstIP (bv 0 32)) (bveq srcPort (bv 0 16)) (bveq dstPort (bv 0 16))) (bv 1 8) 
  (if (and (bveq proto (bv 1 8)) (bveq srcIP (bv 1 32)) (bveq dstIP (bv 1 32)) (bveq srcPort (bv 1 16)) (bveq dstPort (bv 1 16))) (bv 1 8) (bv 0 8))))

(define-grammar (const8)
  [cst (choose (bv 0 8) (bv 1 8) (bv 42 8))])

(define-grammar (const32)
  [cst (choose (bv 0 32) (bv 1 32) (bv 42 32))])

(define-grammar (const16)
  [cst (choose (bv 0 16) (bv 1 16) (bv 42 16) (bv 80 16) (bv 433 16) (bv 21 16))])

;; impl:
(define (impl0 proto srcIP dstIP srcPort dstPort)
  (if (and (bveq proto (const8)) (bveq srcIP (const32)) (bveq dstIP (const32)) (bveq srcPort (const16)) (bveq dstPort (const16))) (bv 1 8) (bv 0 8))   ;;; We MUST use bveq for synthesis
)

(define (impl0vanila proto srcIP dstIP srcPort dstPort)
  (if (and (bveq proto (?? (bitvector 8))) (bveq srcIP (?? (bitvector 32))) (bveq dstIP (?? (bitvector 32))) (bveq srcPort (?? (bitvector 16))) (bveq dstPort (?? (bitvector 16)))) (bv 1 8) (bv 0 8))   ;;; We MUST use bveq for synthesis
)

(define (impl1 proto srcIP dstIP srcPort dstPort)
  (if (and (choose (bveq proto (const8)) #t) (choose (bveq srcIP (const32)) #t) (choose (bveq dstIP (const32)) #t) (choose (bveq srcPort (const16)) #t) (choose (bveq dstPort (const16)) #t)) (bv 1 8) 
  (if (and (choose (bveq proto (const8)) #t) (choose (bveq srcIP (const32)) #t) (choose (bveq dstIP (const32)) #t) (choose (bveq srcPort (const16)) #t) (choose (bveq dstPort (const16)) #t)) (bv 1 8) (bv 0 8)))   ;;; We MUST use bveq for synthesis
)


(define (impl1vanila proto srcIP dstIP srcPort dstPort)
  (if (and (choose (bveq proto (?? (bitvector 8))) #t) (choose (bveq srcIP (?? (bitvector 32))) #t) (choose (bveq dstIP (?? (bitvector 32))) #t) (choose (bveq srcPort (?? (bitvector 16))) #t) (choose (bveq dstPort (?? (bitvector 16))) #t)) (bv 1 8) 
  (if (and (choose (bveq proto (?? (bitvector 8))) #t) (choose (bveq srcIP (?? (bitvector 32))) #t) (choose (bveq dstIP (?? (bitvector 32))) #t) (choose (bveq srcPort (?? (bitvector 16))) #t) (choose (bveq dstPort (?? (bitvector 16))) #t)) (bv 1 8) (bv 0 8)))   ;;; We MUST use bveq for synthesis
)
;;; (define (impl1vanila proto srcIP dstIP srcPort dstPort)
;;;   (if (and (bveq proto (?? (bitvector 8))) (bveq srcIP (?? (bitvector 32))) (bveq dstIP (?? (bitvector 32))) (bveq srcPort (?? (bitvector 16))) (bveq dstPort (?? (bitvector 16)))) (bv 1 8) 
;;;   (if (and (bveq proto (?? (bitvector 8))) (bveq srcIP (?? (bitvector 32))) (bveq dstIP (?? (bitvector 32))) (bveq srcPort (?? (bitvector 16))) (bveq dstPort (?? (bitvector 16)))) (bv 1 8) (bv 0 8)))   ;;; We MUST use bveq for synthesis
;;; )

(define (spectgt proto srcIP dstIP srcPort dstPort)
  (if (and (bveq proto (bv 0 8)) (bveq dstPort (bv 0 16))) (bv 1 8) 
  (if (and (bveq proto (bv 0 8)) (bveq dstPort (bv 433 16))) (bv 1 8)
  (if (and (bveq proto (bv 0 8)) (bveq dstPort (bv 42 16))) (bv 1 8) (bv 0 8)))))   ;;; We MUST use bveq for synthesis

(spectgt (bv 0 8) (bv 1 32) (bv 2 32) (bv 3 16) (bv 81 16)) ; should be 1

(define (impltgt proto srcIP dstIP srcPort dstPort)
  (if (and (choose (bveq proto (const8)) #t) (choose (bveq srcIP (const32)) #t) (choose (bveq dstIP (const32)) #t) (choose (bveq srcPort (const16)) #t) (choose (bveq dstPort (const16)) #t)) (bv 1 8) 
  (if (and (choose (bveq proto (const8)) #t) (choose (bveq srcIP (const32)) #t) (choose (bveq dstIP (const32)) #t) (choose (bveq srcPort (const16)) #t) (choose (bveq dstPort (const16)) #t)) (bv 1 8)
  (if (and (choose (bveq proto (const8)) #t) (choose (bveq srcIP (const32)) #t) (choose (bveq dstIP (const32)) #t) (choose (bveq srcPort (const16)) #t) (choose (bveq dstPort (const16)) #t)) (bv 1 8) (bv 0 8)))
  )   ;;; We MUST use bveq for synthesis
)

(define sol
  (synthesize
   #:forall (list proto srcIP dstIP srcPort dstPort)
   #:guarantee
   (begin
    ;;; (assume (or (bveq proto (bv 0 8)) (bveq proto (bv 1 8))))
    (assert (bveq (spectgt proto srcIP dstIP srcPort dstPort) (impltgt proto srcIP dstIP srcPort dstPort)))
   )
   ))

(if (sat? sol)
    (print-forms sol)
    (displayln "No solution found"))