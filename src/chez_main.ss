;;; Venus Chez Scheme backend entry point
;;; Loaded by the C harness (chez_main.c)
;;; CWD is set to project root by the C harness.

(import (chezscheme))

(define *root* (or (getenv "VENUS_ROOT") (current-directory)))

(load (string-append *root* "/src/lexer.ss"))
(load (string-append *root* "/src/parser.ss"))
(load (string-append *root* "/src/codegen.ss"))

(define (read-file path)
  (call-with-input-file path
    (lambda (port)
      (let loop ((chars '()))
        (let ((c (read-char port)))
          (if (eof-object? c)
              (list->string (reverse chars))
              (loop (cons c chars))))))))

(define (main)
  (let ((args (cdr (command-line))))
    (cond
      ((null? args)
       (display "Usage: vs-chez <file.vs>\n")
       (exit 1))
      (else
       (let* ((filename (car args))
              (source (read-file filename))
              (ast (parse source))
              (lua-code (codegen ast)))
         (display lua-code))))))

(main)
