;;; Venus test helper for Chez Scheme backend

(define *ve-tests* '())

(define (test name thunk)
  (set! *ve-tests* (cons (cons name thunk) *ve-tests*)))

(define (run-tests)
  (set! *ve-tests* (reverse! *ve-tests*))
  (let loop ((tests *ve-tests*) (passed 0) (failed 0))
    (if (null? tests)
        (begin
          (display (string-append "\n" (number->string passed) " passed, "
                                  (number->string failed) " failed\n"))
          (values passed failed))
        (let* ((t (car tests))
               (name (car t))
               (thunk (cdr t)))
          (call-with-current-continuation
           (lambda (return)
             (guard (e (else
                        (display "  FAIL: ") (display name) (newline)
                        (display "    ") (display (condition-message e)) (newline)
                        (loop (cdr tests) passed (+ failed 1))))
               (let ((result (thunk)))
                 (if result
                     (begin
                       (display "  PASS: ") (display name) (newline)
                       (loop (cdr tests) (+ passed 1) failed))
                     (begin
                       (display "  FAIL: ") (display name) (newline)
                       (display "    returned ") (display result) (newline)
                       (loop (cdr tests) passed (+ failed 1))))))))))))
