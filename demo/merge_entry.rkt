#lang rosette

(require rosette/lib/angelic    ; provides choose*
         rosette/lib/destruct)  ; provides destruct

(require rosette/lib/synthax)
(require racket/match)
(require racket/string)   
(require (only-in racket/base string->number))
(require (only-in racket/base error))

(require json racket/port racket/match)

(define int32? (bitvector 32))
(define (int32 i) (bv i int32?))


(struct Rule (match action rewrite) #:transparent)

(struct Match (srcip dstip proto sport dport) #:transparent)
(struct Rewrite (new-src new-dst new-sport new-dport) #:transparent)

(struct packet (srcip dstip proto sport dport) #:transparent)


(define (match? pkt m)
  (and
   (or (equal? (Match-srcip m) #f)
       (equal? (packet-srcip pkt) (Match-srcip m)))
   (or (equal? (Match-dstip m) #f)
       (equal? (packet-dstip pkt) (Match-dstip m)))
   (or (equal? (Match-proto m) #f)
       (equal? (packet-proto pkt) (Match-proto m)))
   (or (equal? (Match-sport m) #f)
       (equal? (packet-sport pkt) (Match-sport m)))
   (or (equal? (Match-dport m) #f)
       (equal? (packet-dport pkt) (Match-dport m)))))

;; generate rules
(define (eval-packet pkt rules)
  (define (apply-rewrite pkt rw)
    (packet
     (or (Rewrite-new-src rw) (packet-srcip pkt))
     (or (Rewrite-new-dst rw) (packet-dstip pkt))
     (packet-proto pkt)
     (or (Rewrite-new-sport rw) (packet-sport pkt))
     (or (Rewrite-new-dport rw) (packet-dport pkt))))

  (define (step pkt rules)
    (cond
      [(null? rules) (cons (int32 1) pkt)] ; default: drop (1), no change
      [else
       (define rule (car rules))
       (if (match? pkt (Rule-match rule))
           (let* ([newpkt (apply-rewrite pkt (Rule-rewrite rule))]
                  [action (Rule-action rule)])
             (cons action newpkt)) ; return (action . newpkt)
           (step pkt (cdr rules)))]))
  (step pkt rules))


; accept is 0, drop is 1
; udp is 0, tcp is 1
; (src dst proto sport dport)
; (Rewrite #f (ip->int32 "192.168.0.2") #f #f), only 4 members in the rewrite because proto is never changed

(define (ip->int32 ip-str)
  (define parts (map string->number (string-split ip-str ".")))
  (define ip-int
    (+ (* (list-ref parts 0) (expt 256 3))
       (* (list-ref parts 1) (expt 256 2))
       (* (list-ref parts 2) (expt 256 1))
       (* (list-ref parts 3) (expt 256 0))))
  (bv ip-int 32))  ; convert to 32-bit bitvector

(define rule1
  (Rule
   (Match #f (ip->int32 "10.0.0.100") (int32 1) #f (int32 80)) ; match dst ip, proto, and dport
   (int32 0)
   (Rewrite #f (ip->int32 "192.168.0.2") #f #f))) ; DNAT

;;; DNAT UDP
(define rule2
  (Rule
   (Match #f (ip->int32 "10.0.0.100") (int32 0) #f (int32 80)) ; match dst ip, proto, and dport
   (int32 0)
   (Rewrite #f (ip->int32 "192.168.0.2") #f #f))) ; DNAT


;;; (define rule2
;;;   (Rule
;;;    (Match (ip->int32 "10.0.0.1") #f (int32 1) #f #f) ; match src ip and proto
;;;    (int32 0)
;;;    (Rewrite #f #f #f #f))) ; no NAT

(define rules (list rule1 rule2))

(define pkt (packet (ip->int32 "10.0.0.0") (ip->int32 "10.0.0.101") (int32 1) (int32 12345) (int32 80)))

(eval-packet pkt rules) ; → 'accept


(define test-pkt
  (packet (ip->int32 "10.0.0.1") (ip->int32 "1.2.3.4") (int32 1) (int32 1234) (int32 80)))

;; define symbolic variables
(define-symbolic src_sym int32?)
(define-symbolic dst_sym int32?)
(define-symbolic proto_sym int32?)
(define-symbolic sport_sym int32?)
(define-symbolic dport_sym int32?)

;; construct symbolic packet
(define sym-pkt (packet src_sym dst_sym proto_sym sport_sym dport_sym))

;; evaluate with existing rules
(define result (eval-packet sym-pkt rules))
(define action (car result))


;;; (define sol
;;;   (solve
;;;   (assert (equal? action (int32 1))))
;;; )

;;; (displayln sol)

;;; TODO realize NAT
(define-grammar (Impl_grammar src_sym dst_sym proto_sym sport_sym dport_sym)
  [expr
   (choose
    (if (cond-expr) (expr) (expr))
    (cons (?? int32?)
          (packet (src_fin)  
                  (dst_fin)  
                  (proto_fin)  
                  (sport_fin)  
                  (dport_fin))) ; return type
    )]
  [src_fin
   (choose
    src_sym
    (?? int32?))]
  [dst_fin
   (choose
    dst_sym
    (?? int32?))]
  [proto_fin
   (choose
    proto_sym
    (?? int32?))]
  [sport_fin
   (choose
    sport_sym
    (?? int32?))]
  [dport_fin
   (choose
    dport_sym
    (?? int32?))]
  [cond-expr
   (choose
    #t
    (equal? (vexpr) (vexpr))
    (and (cond-expr) (cond-expr) (cond-expr) (cond-expr) (cond-expr))
    )]

  [vexpr
   (choose
    src_sym
    dst_sym
    proto_sym
    sport_sym
    dport_sym
    (?? int32?))]     
  )
  

(define (impl-fast srcip dstip proto sport dport)
  (Impl_grammar srcip dstip proto sport dport #:depth 3))


(define sol
    (synthesize
     #:forall    (list src_sym dst_sym proto_sym sport_sym dport_sym)
     #:guarantee (begin
      (assume (or (equal? proto_sym (int32 0)) (equal? proto_sym (int32 1))))
      (assert (equal? (impl-fast src_sym dst_sym proto_sym sport_sym dport_sym) 
                     (eval-packet (packet src_sym dst_sym proto_sym sport_sym dport_sym) rules))))
    )
)

(define sol-str
  (with-output-to-string
    (lambda () (print-forms sol))))

(displayln sol-str)