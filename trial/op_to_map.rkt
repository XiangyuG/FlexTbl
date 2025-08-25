;;; Example 1: basic modifications to the map

;;; #lang rosette

;;; ;; ---------------------------
;;; ;; 1. Initialize
;;; ;; ---------------------------

;;; ;; 空 map
;;; (define (make-empty-map) null)

;;; ;; 带初始元素的 map
;;; (define (make-init-map)
;;;   (list (cons 1 0)
;;;         (cons 2 0)
;;;         (cons 3 0)))

;;; ;; ---------------------------
;;; ;; 2. Lookup
;;; ;; ---------------------------
;;; (define (map-lookup m k)
;;;   (cond
;;;     [(null? m) #f] ; not found
;;;     [(= (car (car m)) k) (cdr (car m))]
;;;     [else (map-lookup (cdr m) k)]))

;;; ;; ---------------------------
;;; ;; 3. Add / Update
;;; ;; ---------------------------
;;; (define (map-add m k v)
;;;   (cond
;;;     [(null? m) (list (cons k v))] ; 空 map → 插入
;;;     [(= (car (car m)) k)
;;;      (cons (cons k v) (cdr m))]   ; key 存在 → 更新
;;;     [else
;;;      (cons (car m) (map-add (cdr m) k v))])) ; 递归继续

;;; ;; ---------------------------
;;; ;; 4. Delete
;;; ;; ---------------------------
;;; (define (map-delete m k)
;;;   (cond
;;;     [(null? m) null]
;;;     [(= (car (car m)) k)
;;;      (cdr m)] ; 跳过该元素，相当于删除
;;;     [else
;;;      (cons (car m) (map-delete (cdr m) k))]))

;;; (define (display-map m)
;;;   (cond
;;;     [(null? m) (displayln "{}")]
;;;     [else
;;;      (display "{")
;;;      (for ([pair m])
;;;        (printf "~a → ~a " (car pair) (cdr pair)))
;;;      (displayln "}")]))
;;; ;; ---------------------------
;;; ;; Example
;;; ;; ---------------------------

;;; (define m0 (make-empty-map))        ; {}
;;; (display-map m0)
;;; (set! m0 (map-add m0 10 100))     ; {10 → 100}
;;; (display-map m0)

#lang rosette

;; --- assoc-list map helpers ---
(define (make-init-map) (list (cons 1 0) (cons 2 0) (cons 3 0)))
(define (present? m k)
  (cond [(null? m) #f]
        [(= (car (car m)) k) #t]
        [else (present? (cdr m) k)]))
(define (lookup m k)
  (cond [(null? m) (error 'lookup "key not found")]
        [(= (car (car m)) k) (cdr (car m))]
        [else (lookup (cdr m) k)]))
(define (remove-key m k)
  (cond [(null? m) null]
        [(= (car (car m)) k) (cdr m)]
        [else (cons (car m) (remove-key (cdr m) k))]))
(define (put m k v) (cons (cons k v) (remove-key m k)))

;; op: 0=add/update, 1=delete, 2=nop (drop 2 if you want to forbid nop)
(define (apply-exec m op k v)
  (cond [(= op 0) (put m k v)]
        [(= op 1) (remove-key m k)]
        [else      m]))

;; symbolic plan: 3 steps
(define-symbolic op1 op2 op3 integer?)
(define-symbolic k1  k2  k3  integer?)
(define-symbolic v1  v2  v3  integer?)

(define (key-in-domain? k) (or (= k 1) (= k 2) (= k 3)))
(define (op-in-domain?  o) (or (= o 0) (= o 1) (= o 2))) ; allow nop=2
(define (bounded? x lo hi) (and (<= lo x) (<= x hi)))

(define m0 (make-init-map))
(define m1 (apply-exec m0 op1 k1 v1))
(define m2 (apply-exec m1 op2 k2 v2))
(define m3 (apply-exec m2 op3 k3 v3))

;; build a single boolean goal instead of using (assert ...)
(define goal
  (&&
   ;; domains
   (op-in-domain? op1) (op-in-domain? op2) (op-in-domain? op3)
   (key-in-domain? k1) (key-in-domain? k2) (key-in-domain? k3)
   (bounded? v1 0 3) (bounded? v2 0 3) (bounded? v3 0 3)
   ;; final shape: exactly {1 -> 0}
   (present? m3 1)
   (= (lookup m3 1) 0)
   (not (present? m3 2))
   (not (present? m3 3))))

(define sol (solve goal))

;; inspect
(define (display-map m)
  (display "{") (for ([p m]) (printf "~a → ~a " (car p) (cdr p))) (displayln "}"))

(define m0* (evaluate m0 sol))
(define m1* (evaluate m1 sol))
(define m2* (evaluate m2 sol))
(define m3* (evaluate m3 sol))

(displayln "Plan chosen:")
(evaluate op1 sol) (evaluate k1 sol) (evaluate v1 sol)
(evaluate op2 sol) (evaluate k2 sol) (evaluate v2 sol)
(evaluate op3 sol) (evaluate k3 sol) (evaluate v3 sol)
;;; (printf "Step1: op=%a k=%a v=%a\n" (evaluate op1 sol) (evaluate k1 sol) (evaluate v1 sol))
;;; (printf "Step2: op=%a k=%a v=%a\n" (evaluate op2 sol) (evaluate k2 sol) (evaluate v2 sol))
;;; (printf "Step3: op=%a k=%a v=%a\n" (evaluate op3 sol) (evaluate k3 sol) (evaluate v3 sol))

;;; (displayln "States:")
;;; (display-map m0*) (display-map m1*) (display-map m2*) (display-map m3*)
