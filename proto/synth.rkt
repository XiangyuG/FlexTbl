#lang rosette/safe


(define-symbolic x y integer?)
(define-symbolic x_match integer?)
(define-symbolic y_match integer?)

; 1 -> tcp; 0 -> udp
(define (Spec x y)
  (if (and (= x 1)
           (= y 22))
      1
      0))

(define (Impl x y)
  (if (and (= x x_match)
           (= y y_match))
      1
      0))

(define spec_result (Spec x y))
(define impl_result (Impl x y))


(define sol
  (synthesize
   #:forall (list x y)
   #:guarantee
   (assert (equal? spec_result impl_result))))

(define x_val (evaluate x_match sol))
(define y_val (evaluate y_match sol))

;; 生成代码字符串
(define result-code
  (format "if (x == ~a && y == ~a) return 1; else return 0;" x_val y_val))

(displayln result-code)