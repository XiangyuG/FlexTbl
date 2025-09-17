#lang rosette/safe
(require rosette/lib/synthax)     ; Require the sketching library.

;;; Example 3: simple synthesis
(define-symbolic proto (bitvector 8))
(define-symbolic srcIP (bitvector 32))
(define-symbolic dstIP (bitvector 32))
(define-symbolic srcPort (bitvector 16))
(define-symbolic dstPort (bitvector 16))

(define (spec0 proto srcIP dstIP srcPort dstPort)
  (if (and (bveq proto (bv 0 8)) (bveq srcIP (bv 1 32)) (bveq dstIP (bv 0 32)) (bveq srcPort (bv 0 16)) (bveq dstPort (bv 0 16))) (bv 1 8) (bv 0 8)))

(define-grammar (const8)
  [cst (choose (bv 0 8) (bv 1 8) (bv 42 8))])

(define-grammar (const32)
  [cst (choose (bv 0 32) (bv 1 32) (bv 42 32))])

(define-grammar (const16)
  [cst (choose (bv 0 16) (bv 1 16) (bv 42 16) (bv 80 16) (bv 433 16) (bv 21 16) (bv 135 16) (bv 445 16))])

;; impl:
(define (impl0 proto srcIP dstIP srcPort dstPort)
  (if (and (bveq proto (const8)) (bveq srcIP (const32)) (bveq dstIP (const32)) (bveq srcPort (const16)) (bveq dstPort (const16))) (bv 1 8) (bv 0 8))   ;;; We MUST use bveq for synthesis
)

(define (impl0vanila proto srcIP dstIP srcPort dstPort)
  (if (and (bveq proto (?? (bitvector 8))) (bveq srcIP (?? (bitvector 32))) (bveq dstIP (?? (bitvector 32))) (bveq srcPort (?? (bitvector 16))) (bveq dstPort (?? (bitvector 16)))) (bv 1 8) (bv 0 8))   ;;; We MUST use bveq for synthesis
)

(define sol
  (synthesize
   #:forall (list proto srcIP dstIP srcPort dstPort)
   #:guarantee
   (begin
    (assert (bveq (spec0 proto srcIP dstIP srcPort dstPort) (impl0vanila proto srcIP dstIP srcPort dstPort)))
   )
   ))

(if (sat? sol)
    (print-forms sol)
    (displayln "No solution found"))