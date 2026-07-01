(define (times n f)
  (let loop ((i 0))
    (when (< i n)
      (f i)
      (loop (+ i 1)))))

(define (assert cond)
  (or cond (error 'assert "assertion failed")))

(define (assert_equal a b)
  (or (equal? a b)
      (error 'assert_equal "expected ~s, got ~s" a b)))

(define (assert_not_equal a b)
  (or (not (equal? a b))
      (error 'assert_not_equal "expected ~s != ~s" a b)))
