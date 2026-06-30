;;; Venus Codegen for Chez Scheme
;;; Generates Scheme source code from Venus AST (association lists).

(define codegen-indent 0)

(define (cg-emit port line)
  (if (= (string-length line) 0)
      (newline port)
      (begin
        (do ((i 0 (+ i 1))) ((>= i codegen-indent))
          (display "  " port))
        (display line port)
        (newline port))))

(define (cg-indent! delta)
  (set! codegen-indent (+ codegen-indent delta)))

(define (ast-type node)
  (let ((p (assq 'type node)))
    (if p (cdr p) #f)))

(define (ast-ref node key)
  (let ((p (assq key node)))
    (if p (cdr p) #f)))

(define (string-replace str from to)
  (let* ((len (string-length str))
         (flen (string-length from))
         (buf (open-output-string)))
    (let loop ((i 0))
      (if (>= i len)
          (get-output-string buf)
          (if (and (<= (+ i flen) len)
                   (string=? (substring str i (+ i flen)) from))
              (begin (display to buf) (loop (+ i flen)))
              (begin (write-char (string-ref str i) buf) (loop (+ i 1))))))))

(define (any pred lst)
  (cond
    ((null? lst) #f)
    ((pred (car lst)) #t)
    (else (any pred (cdr lst)))))

(define (string-join lst sep)
  (if (null? lst)
      ""
      (let loop ((rest (cdr lst)) (result (car lst)))
        (if (null? rest)
            result
            (loop (cdr rest) (string-append result sep (car rest)))))))

(define match-counter 0)

(define module-fields
  (let ((string-fields '("len" "reverse" "repeat_str" "pad" "pad_left" "replace" "chars" "is_empty" "split" "trim" "starts_with" "ends_with" "contains" "concat" "upper"))
        (list-fields '("len" "get" "add" "each" "map" "join" "remove" "filter" "reduce" "range" "flat_map" "zip" "take_while" "drop_while" "flatten" "reverse" "find" "any" "all"))
        (table-fields '("has" "len" "each" "map" "set" "keys" "values" "remove" "merge" "invert" "pick" "omit" "map_keys" "filter" "to_list"))
        (math-fields '("abs" "floor" "ceil" "round" "sqrt" "pow" "max" "min" "pi")))
    (append string-fields list-fields table-fields math-fields)))

(define (module-prefix field obj-type obj-name)
  (cond
    ((eq? obj-type 'list) "List")
    ((eq? obj-type 'table) "Table")
    ((eq? obj-type 'string) "String")
    ((and (eq? obj-type 'ident)
          (or (string=? (string-downcase obj-name) "string")
              (string=? (string-downcase obj-name) "list")
              (string=? (string-downcase obj-name) "table")
              (string=? (string-downcase obj-name) "math")))
     (cond
       ((string=? (string-downcase obj-name) "string") "String")
       ((string=? (string-downcase obj-name) "list") "List")
       ((string=? (string-downcase obj-name) "table") "Table")
       ((string=? (string-downcase obj-name) "math") "Math")))
    ((eq? obj-type 'number) "Math")
    ((eq? obj-type 'string) "String")
    (else #f)))

(define (ident->scheme name)
  (string-replace name "." "-"))
(define (field->func field) field)

(define (cg-process-string val)
  (let ((len (string-length val)))
    (if (and (>= len 6)
             (string=? (substring val 0 3) "\"\"\"")
             (string=? (substring val (- len 3) len) "\"\"\""))
        (string-append "\""
                       (string-replace
                        (string-replace
                         (substring val 3 (- len 3))
                         "\\" "\\\\")
                        "\"" "\\\"")
                       "\"")
        val)))

(define (cg-has-literal-params fn-node)
  (any (lambda (p) (eq? (ast-ref p 'is-literal) #t))
       (ast-ref fn-node 'params)))

(define (cg-preprocess node)
  (if (not (eq? (ast-type node) 'program))
      node
      (let ((body (ast-ref node 'body)))
        (let ((groups (let loop ((stmts body) (acc '()))
                        (if (null? stmts)
                            acc
                            (let* ((s (car stmts))
                                   (name (and (eq? (ast-type s) 'fn) (ast-ref s 'name))))
                              (if name
                                  (let ((existing (assq (string->symbol name) acc)))
                                    (if existing
                                        (begin (set-cdr! existing (cons s (cdr existing)))
                                               (loop (cdr stmts) acc))
                                        (loop (cdr stmts)
                                              (cons (cons (string->symbol name) (list s)) acc))))
                                  (loop (cdr stmts) acc)))))))
          (let ((emitted '())
                (new-body '()))
            (for-each
             (lambda (stmt)
               (let ((name (and (eq? (ast-type stmt) 'fn) (ast-ref stmt 'name))))
                 (if name
                     (let ((sym (string->symbol name)))
                       (unless (memq sym emitted)
                         (set! emitted (cons sym emitted))
                         (set! new-body
                               (cons (ast 'overloaded_fn
                                          (cons 'name name)
                                          (cons 'overloads (reverse! (cdr (assq sym groups)))))
                                     new-body))))
                     (set! new-body (cons stmt new-body)))))
             body)
            (ast 'program (cons 'body (reverse! new-body))))))))

(define (cg-emit-bindings port names values)
  (let ((bindings (map (lambda (n v)
                         (string-append "(" n " " v ")"))
                       names
                       (if (null? values)
                           (map (lambda (n) "#f") names)
                           (map (lambda (v) (cg-emit-expr port v)) values)))))
    (string-append "(" (string-join bindings " ") ")")))

(define (cg-emit-fn-body port body)
  (let loop ((stmts body))
    (if (null? stmts)
        'done
        (let ((stmt (car stmts))
              (rest (cdr stmts)))
          (if (eq? (ast-type stmt) 'let)
              (let ((names (ast-ref stmt 'names))
                    (values (ast-ref stmt 'values)))
                (cg-emit port (string-append "(let "
                                             (cg-emit-bindings port names values)))
                (cg-indent! 1)
                (loop rest)
                (cg-indent! -1)
                (cg-emit port ")"))
              (let ((line (cg-emit-expr port stmt)))
                (when (not (string=? line ""))
                  (cg-emit port line))
                 (loop rest)))))))
 
(define (cg-emit-fn-def port name params body)
  (let ((param-list (if (null? params)
                        " . ___rest"
                        (string-append " " (string-join params " ") " . ___rest"))))
    (cg-emit port (string-append "(define (" name param-list ")"))
    (cg-indent! 1)
    (cg-emit-fn-body port body)
    (cg-indent! -1)
    (cg-emit port ")")))

(define (cg-literal-test params)
  (let ((lits (filter (lambda (p) (eq? (ast-ref p 'is-literal) #t)) params)))
    (if (null? lits)
        "else"
        (let ((tests (map (lambda (p)
                            (string-append "(equal? " (ast-ref p 'value) " n)"))
                          lits)))
          (if (= (length tests) 1)
              (car tests)
              (string-append "(and " (string-join tests " ") ")"))))))

(define (cg-emit-overloaded port name overloads)
  (if (and (= (length overloads) 1)
           (not (cg-has-literal-params (car overloads))))
      (let* ((fn (car overloads))
             (params (map (lambda (p) (or (ast-ref p 'name) (ast-ref p 'value)))
                         (ast-ref fn 'params))))
        (cg-emit-fn-def port name params (ast-ref fn 'body)))
      (begin
        (cg-emit port (string-append "(define (" name " . args)"))
        (cg-indent! 1)
        (cg-emit port "(let ((n (car args)))")
        (cg-indent! 1)
        (cg-emit port "(cond")
        (cg-indent! 1)
        (for-each
         (lambda (ol)
           (let ((test (cg-literal-test (ast-ref ol 'params))))
             (cg-emit port (string-append "(" test))
             (cg-indent! 1)
             (cg-emit-fn-body port (ast-ref ol 'body))
             (cg-indent! -1)
             (cg-emit port ")")))
         overloads)
        (cg-indent! -1)
        (cg-emit port ")")
        (cg-indent! -1)
        (cg-emit port ")")
        (cg-indent! -1)
        (cg-emit port ")")))
  "")

 (define (cg-emit-expr port node)
  (let ((type (ast-type node)))
    (cond
      ((eq? type 'number)
       (ast-ref node 'value))

      ((eq? type 'string)
       (cg-process-string (ast-ref node 'value)))

      ((eq? type 'interp-string)
       (string-append "(string-append "
                       (string-join
                        (map (lambda (part)
                               (if (eq? (ast-type part) 'string)
                                   (cg-process-string (ast-ref part 'value))
                                   (string-append "(venus-tostring " (cg-emit-expr port part) ")")))
                             (ast-ref node 'parts))
                        " ")
                       ")"))

      ((eq? type 'nil)
       "#f")

      ((eq? type 'true)
       "#t")

       ((eq? type 'false)
        "'()")

      ((eq? type 'ident)
       (ident->scheme (ast-ref node 'name)))

       ((eq? type 'member)
        (string-append "(cdr (assoc \"" (ast-ref node 'field) "\" (tu "
                       (cg-emit-expr port (ast-ref node 'object)) ")))"))

       ((eq? type 'safe-member)
        (let ((obj (cg-emit-expr port (ast-ref node 'object)))
              (fields (ast-ref node 'fields)))
          (string-append "(and " obj
                         " (let ((_v (assoc \"" (car fields) "\" (tu " obj ")))) (and _v (cdr _v))))")))

      ((eq? type 'binary)
       (let ((left (cg-emit-expr port (ast-ref node 'left)))
             (op (ast-ref node 'op))
             (right (cg-emit-expr port (ast-ref node 'right))))
         (cond
            ((string=? op "==")
             (string-append "(if (equal? " left " " right ") #t '())"))
            ((string=? op "!=")
             (string-append "(if (not (equal? " left " " right ")) #t '())"))
           ((string=? op "and")
            (string-append "(and " left " " right ")"))
           ((string=? op "or")
            (string-append "(or " left " " right ")"))
           (else
            (string-append "(" op " " left " " right ")")))))

       ((eq? type 'unary)
        (let ((operand (cg-emit-expr port (ast-ref node 'operand)))
              (op (ast-ref node 'op)))
          (if (string=? op "!")
              (string-append "(if (not " operand ") #t '())")
              (string-append "(- " operand ")"))))

       ((eq? type 'call)
        (let* ((callee-raw (ast-ref node 'callee))
               (args (ast-ref node 'args))
               (arg-strs (map (lambda (a) (cg-emit-expr port a)) args))
               (args-joined (string-join arg-strs " ")))
           (if (and (pair? callee-raw) (eq? (ast-type callee-raw) 'member))
                (let* ((field (ast-ref callee-raw 'field))
                       (obj-raw (ast-ref callee-raw 'object))
                       (obj-type (ast-type obj-raw))
                       (obj-name (and (eq? obj-type 'ident) (ast-ref obj-raw 'name)))
                       (obj (cg-emit-expr port obj-raw))
                       (prefix (module-prefix field obj-type obj-name)))
                  (if prefix
                      (if (and (eq? obj-type 'ident)
                               (string=? (string-downcase obj-name)
                                         (string-downcase prefix)))
                           (string-append "(" prefix "-" (field->func field) " " args-joined ")")
                           (string-append "(" prefix "-" (field->func field) " " obj " " args-joined ")"))
                       (string-append "((cdr (assoc \"" field "\" (tu " obj "))) " args-joined ")")))
              (let ((callee
                     (cond
                       ((string? callee-raw) callee-raw)
                       ((eq? (ast-type callee-raw) 'lambda) (cg-emit-expr port callee-raw))
                       (else (cg-emit-expr port callee-raw)))))
                (if (string=? callee "print")
                    (string-append "(vs-print " args-joined ")")
                    (string-append "(" callee (if (string=? args-joined "") "" (string-append " " args-joined)) ")"))))))

      ((eq? type 'let)
       (let ((names (ast-ref node 'names))
             (values (ast-ref node 'values)))
         (if (null? values)
             (string-append "(define " (car names) " #f)")
             (string-append "(define " (car names)
                            " " (cg-emit-expr port (car values)) ")"))))

      ((eq? type 'lambda)
       (let ((saved-indent codegen-indent)
             (body (ast-ref node 'body)))
                  (let* ((pl (ast-ref node 'params))
                         (params-str (if (null? pl)
                                        " ___rest"
                                        (string-append "(" (string-join pl " ") " . ___rest)"))))
                    (let ((result
                           (with-output-to-string
                             (lambda ()
                               (let ((port (current-output-port)))
                                 (cg-emit port (string-append "(lambda" params-str))
                                 (cg-indent! 1)
                                 (if (null? body)
                                     (cg-emit port "#f")
                                     (cg-emit-fn-body port body))
                                 (cg-indent! -1)
                                  (cg-emit port ")"))))))
            (set! codegen-indent saved-indent)
            result))))

       ((eq? type 'fn)
        (cg-emit-fn-def port (ast-ref node 'name)
                        (map (lambda (p) (or (ast-ref p 'name) (ast-ref p 'value)))
                             (ast-ref node 'params))
                        (ast-ref node 'body))
        "")

      ((eq? type 'overloaded_fn)
       (cg-emit-overloaded port (ast-ref node 'name) (ast-ref node 'overloads)))

      ((eq? type 'list)
       (let ((vals (map (lambda (v) (cg-emit-expr port v)) (ast-ref node 'values))))
         (string-append "(venus-list " (string-join vals " ") ")")))

       ((eq? type 'table)
        (let ((fields (map (lambda (f)
                             (string-append "(cons \""
                                            (ast-ref f 'key) "\" "
                                            (cg-emit-expr port (ast-ref f 'value)) ")"))
                           (ast-ref node 'fields))))
          (string-append "(venus-table (list " (string-join fields " ") "))")))

       ((eq? type 'if)
        (let ((saved-indent codegen-indent))
          (let ((result
                 (with-output-to-string
                   (lambda ()
                     (let ((p (current-output-port)))
                       (cg-emit p "(cond")
                       (cg-indent! 1)
                       (cg-emit p (string-append "(" (cg-emit-expr p (ast-ref node 'condition))))
                       (cg-indent! 1)
                       (cg-emit-fn-body p (ast-ref node 'body))
                       (cg-indent! -1)
                       (cg-emit p ")")
                       (for-each
                        (lambda (ei)
                          (cg-emit p (string-append "(" (cg-emit-expr p (ast-ref ei 'condition))))
                          (cg-indent! 1)
                          (cg-emit-fn-body p (ast-ref ei 'body))
                          (cg-indent! -1)
                          (cg-emit p ")"))
                        (ast-ref node 'else-ifs))
                       (when (ast-ref node 'else-body)
                         (cg-emit p "(else")
                         (cg-indent! 1)
                         (cg-emit-fn-body p (ast-ref node 'else-body))
                         (cg-indent! -1)
                         (cg-emit p ")"))
                       (cg-indent! -1)
                       (cg-emit p ")"))))))
           (set! codegen-indent saved-indent)
           result)))

       ((eq? type 'match)
        (set! match-counter (+ match-counter 1))
        (let ((tmp (string-append "_m_" (number->string match-counter)))
              (value-code (cg-emit-expr port (ast-ref node 'value))))
          (let ((saved-indent codegen-indent))
            (let ((result
                   (with-output-to-string
                     (lambda ()
                       (let ((p (current-output-port)))
                         (cg-emit p (string-append "(let ((" tmp " " value-code "))"))
                         (cg-indent! 1)
                         (cg-emit p "(cond")
                         (cg-indent! 1)
                         (for-each
                          (lambda (arm)
                            (let* ((pat (ast-ref arm 'pattern))
                                   (body-code (cg-emit-expr p (ast-ref arm 'body))))
                              (cond
                                ((eq? (ast-type pat) 'wildcard)
                                 (cg-emit p "(else")
                                 (cg-indent! 1)
                                 (cg-emit p body-code)
                                 (cg-indent! -1)
                                 (cg-emit p ")"))
                                ((eq? (ast-type pat) 'ident)
                                 (cg-emit p (string-append "(else"
                                                           " (let ((" (ast-ref pat 'name) " " tmp "))"))
                                 (cg-indent! 1)
                                 (cg-emit p body-code)
                                 (cg-indent! -1)
                                 (cg-emit p "))"))
                                (else
                                 (let ((pat-code (cg-emit-expr p pat)))
                                   (cg-emit p (string-append "((equal? " tmp " " pat-code ")"))
                                   (cg-indent! 1)
                                   (cg-emit p body-code)
                                   (cg-indent! -1)
                                   (cg-emit p ")"))))))
                          (ast-ref node 'arms))
                         (cg-indent! -1)
                         (cg-emit p ")")
                         (cg-indent! -1)
                         (cg-emit p ")"))))))
              (set! codegen-indent saved-indent)
              result))))

       ((eq? type 'import)
        (string-append "(vs-import \"" (ast-ref node 'path) "\")"))

       ((eq? type 'export)
        (let ((val (ast-ref node 'value)))
          (if (eq? (ast-type val) 'table)
              (let ((fields (ast-ref val 'fields)))
                (string-join
                 (map (lambda (f)
                        (string-append "(vs-export! \"" (ast-ref f 'key) "\" "
                                       (cg-emit-expr port (ast-ref f 'value)) ")"))
                      fields)
                 "\n"))
              (string-append "(begin)"))))

       ((eq? type 'placeholder)
        (error 'codegen "placeholder outside pipeline context"))

      ((eq? type 'program)
       (cg-emit port "(import (chezscheme))")
       (cg-emit port "")
       (cg-emit port "(define (vs-print . args)")
       (cg-indent! 1)
       (cg-emit port "(unless (null? args)")
       (cg-indent! 1)
       (cg-emit port "(display (car args))")
       (cg-emit port "(for-each (lambda (x) (display \" \") (display x)) (cdr args))")
       (cg-indent! -1)
       (cg-emit port ")")
       (cg-emit port "(newline)")
       (cg-indent! -1)
       (cg-emit port ")")
       (cg-emit port "")
       (for-each
        (lambda (stmt)
          (let ((line (cg-emit-expr port stmt)))
            (when (not (string=? line ""))
              (cg-emit port line))))
        (ast-ref node 'body))
       "")

      (else
       (error 'codegen (format "Unknown node type: ~s" type))))))

(define (codegen ast)
  (set! codegen-indent 0)
  (set! match-counter 0)
  (let ((processed (cg-preprocess ast))
        (port (open-output-string)))
    (cg-emit-expr port processed)
    (let ((result (get-output-string port)))
      (if (and (> (string-length result) 0)
               (char=? (string-ref result (- (string-length result) 1)) #\newline))
          (substring result 0 (- (string-length result) 1))
          result))))
