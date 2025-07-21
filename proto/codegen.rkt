#lang racket

(provide expr->c
         indent-lines
         bv->c
         indent-str
         bv-const?)

(define rosette-func-body
  ;;; '(if (and (equal? lo lo) (equal? (bv #x00080000 32) (bv #x00000000 32)))
  ;;;   (bv #x00000000 32)
  ;;;   (if (and (equal? (bv #x00000016 32) hi) (equal? (bv #x00000001 32) lo))
  ;;;     lo
  ;;;     (bv #x00000000 32))))

  ;;; '(if (and (equal?
  ;;;           (if (and (equal? hi (bv #x00000010 32)) (equal? hi hi))
  ;;;             (bv #x00000000 32)
  ;;;             hi)
  ;;;           (bv #x00000016 32))
  ;;;          (equal?
  ;;;           (if (and (equal? (bv #x00000001 32) lo)
  ;;;                    (equal? (bv #x00000001 32) lo))
  ;;;             lo
  ;;;             (bv #x00000000 32))
  ;;;           lo))
  ;;;   (if (and (equal? lo lo) (equal? (bv #xffffffe9 32) hi))
  ;;;     (bv #x00000000 32)
  ;;;     (bv #x00000001 32))
  ;;;   (bv #x00000000 32)))
  '(if (and (equal? lo (bv #x00000001 32))
           (equal? (bv #x00000000 32) (bv #x00000000 32)))
    (if (equal? hi (bv #x00000016 32)) (bv #x00000001 32) (bv #x00000000 32))
    (if (equal? (bv #x00000200 32) hi) (bv #x00000000 32) (bv #x00000000 32))))



(define (bv->c bv-expr)
  (match bv-expr
    [(list 'bv val bitsize)
     (format "~a" (number->string val 10))]))

(define (indent-str level)
  (make-string (* 2 level) #\space))

(define (bv-const? expr)
  (and (list? expr)
       (= (length expr) 3)
       (eq? (first expr) 'bv)
       (number? (second expr))))

(define (indent-lines str indent)
  (define prefix (indent-str indent))
  (string-join (map (lambda (line) (string-append prefix line))
                    (string-split str "\n"))
               "\n"))

(define (expr->c expr [indent-level 0])
  (match expr
    [(list 'bv val bits) (bv->c expr)]

    [(list 'bvadd a b)
        (cond
        [(and (list? a) (list? b)
                (eq? (first a) 'bv) (eq? (first b) 'bv))
            (define val-a (second a))
            (define val-b (second b))
            (define bits (third a))
            (format "~a" (modulo (+ val-a val-b) (expt 2 bits)))]

        ;; otherwise do normal codegen
        [else
            (format "(~a + ~a)" (expr->c a indent-level) (expr->c b indent-level))])]

    [(list 'bvsub a b)
        (cond
            [(and (list? a) (list? b)
                    (eq? (first a) 'bv) (eq? (first b) 'bv))
                (define val-a (second a))
                (define val-b (second b))
                (define bits (third a)) ; assume a and b have the same bit width
                (format "~a" (modulo (+ val-a val-b) (expt 2 bits)))]

            ;; otherwise, do normal codegen
            [else
                (format "(~a - ~a)" (expr->c a indent-level) (expr->c b indent-level))])]

    [(list 'equal? a b)
     (format "(~a == ~a)" (expr->c a indent-level) (expr->c b indent-level))]

    [(list 'and a b)
     (format "(~a && ~a)" (expr->c a indent-level) (expr->c b indent-level))]

    [(list 'or a b)
     (format "(~a || ~a)" (expr->c a indent-level) (expr->c b indent-level))]

    [(list 'if cond then else)
 (let* ([ind (indent-str indent-level)]
        [ind-next (indent-str (+ indent-level 1))]
        [then-str (expr->c then (+ indent-level 1))]
        [else-str (expr->c else (+ indent-level 1))]
        [then-out (if (and (list? then) (equal? (first then) 'if))
                     then-str
                     (if (bv-const? then)
                         (match (string->number then-str)
                           [0 "return XDP_DROP;"]
                           [1 "return XDP_PASS;"]
                           [_ (format "return ~a;" then-str)])
                         (format "return ~a;" then-str)))]
        [else-out (if (and (list? else) (equal? (first else) 'if))
                     else-str
                     (if (bv-const? else)
                         (match (string->number else-str)
                           [0 "return XDP_DROP;"]
                           [1 "return XDP_PASS;"]
                           [_ (format "return ~a;" else-str)])
                         (format "return ~a;" else-str)))]
                )
   (format "~aif ~a {\n~a~a\n~a} else {\n~a~a\n~a}"
           ind
           (expr->c cond indent-level)
           ind-next 
           then-out
           ind
           ind-next 
           else-out
           ind))]

    [x (symbol->string x)]
    ))


(define core_eBPF (expr->c rosette-func-body))

(define xdp-wrapper
  (string-append
"#include <uapi/linux/bpf.h>
#include <uapi/linux/if_ether.h>
#include <uapi/linux/ip.h>
#include <uapi/linux/in.h>

int xdp_prog(struct xdp_md *ctx) {
  void* data_end = (void*)(long)ctx->data_end;
  void* data     = (void*)(long)ctx->data;

  struct ethhdr *eth = data;
  if ((void*)(eth + 1) > data_end)
    return XDP_DROP;

  // Check EtherType
  if (eth->h_proto != __constant_htons(ETH_P_IP))
    return XDP_PASS;

  struct iphdr *ip = (void*)(eth + 1);
  if ((void*)(ip + 1) > data_end)
    return XDP_DROP;

  unsigned int lo = ip->protocol;
  unsigned int hi = ip->saddr;

  // --- BEGIN GENERATED LOGIC ---\n"
  core_eBPF
"\n  
// --- END GENERATED LOGIC ---
return XDP_DROP;\t
}"))


(displayln xdp-wrapper)