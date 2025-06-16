#lang racket
(require racket/lang/reader)

(provide (rename-out [read-syntax-filter read-syntax]
                     [read-filter read]))

(define (read-filter in) (read-syntax #f in))
(define (read-syntax-filter src in)
  (parameterize ([current-readtable (make-readtable #f)])
    (read-syntax src in)))
