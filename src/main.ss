;;; Venus Chez Scheme backend entry point
;;; Loaded by the C harness (chez_main.c)
;;; CWD is set to project root by the C harness.

(import (chezscheme))

;; Try to load libedit for readline support in REPL
(define *have-readline* #f)
(define *readline-fn* #f)
(define *add-history-fn* #f)

(guard (e (else #f))
  (load-shared-object "libedit.dylib")
  (set! *readline-fn* (foreign-procedure "readline" (string) string))
  (set! *add-history-fn* (foreign-procedure "add_history" (string) void))
  (set! *have-readline* #t))

(define *root* (or (getenv "VENUS_ROOT") (current-directory)))

(library-directories (list (string-append *root* "/src") "."))

(load (string-append *root* "/src/lexer.ss"))
(load (string-append *root* "/src/parser.ss"))
(load (string-append *root* "/src/codegen.ss"))
(load (string-append *root* "/src/runtime.ss"))

;; Load Venus standard library extensions into the interaction environment.
;; Each Venus export is a top-level binding created by the codegen.
;; We reference functions by name so eval can look them up.
(define (load-ve-extension! path module-name)
  (let ((exports (ve-import path)))
    (for-each (lambda (kv)
                (let ((key (car kv))
                      (var-name (string->symbol (car kv))))
                  (eval `(set! ,module-name
                               (cons (cons ,key ,var-name) ,module-name)))))
              exports)))

(load-ve-extension! "src/string.ve" 'String)
(load-ve-extension! "src/list.ve" 'List)
(load-ve-extension! "src/table.ve" 'Table)
(load-ve-extension! "src/vector.ve" 'Vector)
(load-ve-extension! "src/map.ve" 'Map)

;; Load global built-in functions
(load (string-append *root* "/src/builtins.ss"))

(define (read-file path)
  (call-with-input-file path
    (lambda (port)
      (let loop ((chars '()))
        (let ((c (read-char port)))
          (if (eof-object? c)
              (list->string (reverse chars))
              (loop (cons c chars))))))))

(define (compile-source source)
  (let* ((ast (parse source))
         (code (codegen ast)))
    code))

(define (eval-code code)
  (let ((port (open-input-string code)))
    (let loop ()
      (let ((expr (read port)))
        (unless (eof-object? expr)
          (eval expr (interaction-environment))
          (loop))))))

(define (string-contains? s substr)
  (let ((slen (string-length s))
        (sublen (string-length substr)))
    (let loop ((i 0))
      (and (<= (+ i sublen) slen)
           (or (string=? (substring s i (+ i sublen)) substr)
               (loop (+ i 1)))))))

(define (eval-code/run-tests code)
  (eval-code code)
  (guard (e (else #f))
    (when (and (not (null? *ve-tests*)) (procedure? run-tests))
      (run-tests))))

(define (display-code code)
  (display code)
  (when (and (> (string-length code) 0)
             (not (char=? (string-ref code (- (string-length code) 1)) #\newline)))
    (newline)))

(define (usage)
  (display "Usage: ve [options] <file.ve>\n")
  (display "Options:\n")
  (display "  -c           Print compiled Scheme only (do not run)\n")
  (display "  -e <code>    Execute Venus code from string\n")
  (display "  --repl       Start interactive REPL\n")
  (display "  --help       Show this help\n")
  (exit 1))

(define (repl)
  (display "Venus REPL\n")
  (let loop ()
    (let ((line (if *have-readline*
                    (*readline-fn* "> ")
                    (begin (display "> ")
                           (flush-output-port (current-output-port))
                           (get-line (current-input-port))))))
      (when (and line (not (string=? line "")))
        (when *have-readline*
          (*add-history-fn* line))
        (let ((code (guard (e (else
                               (display "Error: ")
                               (display (condition-message e))
                               (newline) #f))
                      (compile-source line))))
          (when code
            (guard (e (else
                       (display "Error: ")
                       (display (condition-message e))
                       (newline)))
              (let ((port (open-input-string code)))
                (let eval-loop ()
                  (let ((expr (read port)))
                    (unless (eof-object? expr)
                      (let ((val (eval expr (interaction-environment))))
                        (unless (eq? val (void))
                          (venus-write val) (newline)))
                      (eval-loop)))))))))
      (when line (loop)))))

(define (main)
  (let ((args (cdr (command-line))))
    (let parse-args ((remaining args)
                     (compile-only #f)
                     (inline-code #f)
                     (filename #f))
      (cond
        ((and (null? remaining) (not inline-code) (not filename))
         (repl))
        ((and (null? remaining) inline-code)
         (let ((code (compile-source inline-code)))
           (if compile-only
               (display-code code)
               (eval-code code))))
        ((and (null? remaining) filename)
         (let* ((source (read-file filename))
                (code (compile-source source)))
           (if compile-only
               (display-code code)
               (begin
                 (when (string-contains? filename "test/")
                    (load (string-append *root* "/src/test.ss")))
                 (eval-code/run-tests code)))))
        (else
         (let ((arg (car remaining))
               (rest (cdr remaining)))
           (cond
             ((string=? arg "-c")
              (parse-args rest #t inline-code filename))
             ((string=? arg "-e")
               (if (null? rest)
                   (usage)
                   (parse-args (cdr rest) compile-only (car rest) filename)))
             ((string=? arg "--repl")
              (repl))
             ((string=? arg "--help")
              (usage))
             ((char=? (string-ref arg 0) #\-)
              (display (string-append "Unknown option: " arg "\n"))
              (usage))
             (else
              (parse-args rest compile-only inline-code arg)))))))))

(main)
