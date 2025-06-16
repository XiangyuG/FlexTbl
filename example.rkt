#lang s-exp "FlexTblDSL/main.rkt"

(define-rule
  (chain INPUT)
  (protocol tcp)
  (dport 22)
  (action ACCEPT))

(define-rule
  (chain INPUT)
  (protocol udp)
  (dport 53)
  (action DROP))
