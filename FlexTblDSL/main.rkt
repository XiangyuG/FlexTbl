#lang racket/base
(provide define-rule #%module-begin)

(require (for-syntax syntax/parse))

(define-syntax #%module-begin
  (syntax-rules ()
    [(_ body ...)
     (#%plain-module-begin
      body ...)]))

(define-syntax-rule
  (define-rule (chain ch) (protocol proto) (dport port) (action act))
  (begin
    (printf "iptables -A ~a -p ~a --dport ~a -j ~a\n"
            'ch 'proto 'port 'act)))
