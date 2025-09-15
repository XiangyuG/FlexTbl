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
(define-symbolic x (bitvector 8))

;; spec: 只有 x=0 时返回 1
(define (spec x)
  (if (bveq x (bv 0 8)) (bv 1 8) (bv 0 8)))

;; grammar: 候选常量
(define-grammar (const8)
  [cst (choose (bv 0 8) (bv 1 8) (bv 42 8))])

;; impl: 待合成
(define (impl x)
  (if (bveq x (const8)) (bv 1 8) (bv 0 8)))   ;;; We MUST use bveq for synthesis

(define sol
  (synthesize
   #:forall (list x)
   #:guarantee
   (assert (bveq (spec x) (impl x)))))

(if (sat? sol)
    (print-forms sol)
    (displayln "No solution found"))