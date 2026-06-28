;;; Venus Codegen for Chez Scheme
;;; Generates Lua source code from Venus AST (association lists).

(load "src/parser.ss")

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

;;; Preprocess: group overloaded fn declarations
(define (cg-preprocess node)
  (if (not (eq? (ast-type node) 'program))
      node
      (let* ((body (ast-ref node 'body))
             (groups (let loop ((stmts body) (acc '()))
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
          (ast 'program (cons 'body (reverse! new-body)))))))

;;; Check if any param is literal
(define (cg-has-literal-params fn-node)
  (any (lambda (p) (eq? (ast-ref p 'is-literal) #t))
       (ast-ref fn-node 'params)))

;;; Emit body statements, returning last expression
(define (cg-emit-fn-body port body return-last?)
  (let loop ((stmts body) (idx 0))
    (unless (null? stmts)
      (let* ((stmt (car stmts))
             (line (cg-emit-expr port stmt)))
        (when (and (not (string=? line ""))
                   return-last?
                   (= idx (- (length body) 1))
                   (not (memq (ast-type stmt) '(let if match overloaded-fn))))
          (set! line (string-append "return " line)))
        (when (not (string=? line ""))
          (cg-emit port line))
        (loop (cdr stmts) (+ idx 1))))))

;;; Emit expression; returns the Lua string for expressions,
;;; or "" for statements (which are emitted directly)
(define (cg-emit-expr port node)
  (let ((type (ast-type node)))
    (cond
      ((eq? type 'number)
       (ast-ref node 'value))

      ((eq? type 'string)
       (ast-ref node 'value))

      ((eq? type 'interp-string)
       (string-join
        (map (lambda (part)
               (if (eq? (ast-type part) 'string)
                   (ast-ref part 'value)
                   (cg-emit-expr port part)))
             (ast-ref node 'parts))
        " .. "))

      ((eq? type 'nil)
       "nil")

      ((eq? type 'true)
       "true")

      ((eq? type 'false)
       "false")

      ((eq? type 'ident)
       (ast-ref node 'name))

      ((eq? type 'import)
       (let ((path (ast-ref node 'path)))
         (if (and (>= (string-length path) 3)
                  (string=? (substring path (- (string-length path) 3) (string-length path)) ".vs"))
             (string-append "vs_require(\"" path "\")")
             (string-append "require(\"" path "\")"))))

      ((eq? type 'export)
       (string-append "return " (cg-emit-expr port (ast-ref node 'value))))

      ((eq? type 'member)
       (string-append (cg-emit-expr port (ast-ref node 'object))
                      "." (ast-ref node 'field)))

      ((eq? type 'safe_member)
       (let ((obj (cg-emit-expr port (ast-ref node 'object)))
             (fields (ast-ref node 'fields)))
         (let ((chain (string-append obj
                                      (apply string-append
                                             (map (lambda (f) (string-append "." f)) fields)))))
           (string-append "(" obj " ~= nil and " chain " or nil)"))))

      ((eq? type 'binary)
       (let ((left (cg-emit-expr port (ast-ref node 'left)))
             (op (ast-ref node 'op))
             (right (cg-emit-expr port (ast-ref node 'right))))
         (let ((lua-op (if (string=? op "!=") "~=" op)))
           (string-append "(" left " " lua-op " " right ")"))))

      ((eq? type 'unary)
       (let ((operand (cg-emit-expr port (ast-ref node 'operand)))
             (op (ast-ref node 'op)))
         (if (string=? op "!")
             (string-append "(not " operand ")")
             (string-append "(-" operand ")"))))

      ((eq? type 'call)
       (let* ((callee-raw (ast-ref node 'callee))
              (callee (if (string? callee-raw)
                          callee-raw
                          (let ((s (cg-emit-expr port callee-raw)))
                            (if (eq? (ast-type callee-raw) 'lambda)
                                (string-append "(" s ")")
                                s))))
              (args (ast-ref node 'args))
              (arg-strs (map (lambda (a) (cg-emit-expr port a)) args)))
         (string-append callee "(" (string-join arg-strs ", ") ")")))

      ((eq? type 'let)
       (let ((names (ast-ref node 'names))
             (values (ast-ref node 'values)))
         (if (null? values)
             (string-append "local " (string-join names ", "))
             (let ((rhs (map (lambda (v) (cg-emit-expr port v)) values)))
               (string-append "local " (string-join names ", ")
                              " = " (string-join rhs ", "))))))

      ((eq? type 'lambda)
       (let ((saved-indent codegen-indent))
         (let ((result
                (with-output-to-string
                  (lambda ()
                    (let ((port (current-output-port)))
                      (cg-emit port (string-append "function(" (string-join (ast-ref node 'params) ", ") ")"))
                      (cg-indent! 1)
                      (cg-emit-fn-body port (ast-ref node 'body) #t)
                      (cg-indent! -1)
                      (cg-emit port "end"))))))
           (set! codegen-indent saved-indent)
           result)))

      ((eq? type 'fn)
       (let ((params (map (lambda (p) (ast-ref p 'name)) (ast-ref node 'params))))
         (cg-emit port (string-append "local function " (ast-ref node 'name)
                                       "(" (string-join params ", ") ")"))
         (cg-indent! 1)
         (cg-emit-fn-body port (ast-ref node 'body) #t)
         (cg-indent! -1)
         (cg-emit port "end")
         ""))

      ((eq? type 'overloaded_fn)
       (cg-emit-overloaded-fn port node))

      ((eq? type 'list)
       (let ((vals (map (lambda (v) (cg-emit-expr port v)) (ast-ref node 'values))))
         (string-append "{ " (string-join vals ", ") " }")))

      ((eq? type 'table)
       (let ((fields (map (lambda (f)
                            (string-append "[\"" (ast-ref f 'key) "\"] = "
                                           (cg-emit-expr port (ast-ref f 'value))))
                          (ast-ref node 'fields))))
         (string-append "{ " (string-join fields ", ") " }")))

      ((eq? type 'if)
       (let ((saved-indent codegen-indent)
             (result
              (with-output-to-string
                (lambda ()
                  (let ((p (current-output-port)))
                    (cg-emit p (string-append "if " (cg-emit-expr p (ast-ref node 'condition)) " then"))
                    (cg-indent! 1)
                    (cg-emit-fn-body p (ast-ref node 'body) #t)
                    (cg-indent! -1)
                    (for-each
                     (lambda (ei)
                       (cg-emit p (string-append "elseif "
                                                 (cg-emit-expr p (ast-ref ei 'condition)) " then"))
                       (cg-indent! 1)
                       (cg-emit-fn-body p (ast-ref ei 'body) #t)
                       (cg-indent! -1))
                     (ast-ref node 'else-ifs))
                    (when (ast-ref node 'else-body)
                      (cg-emit p "else")
                      (cg-indent! 1)
                      (cg-emit-fn-body p (ast-ref node 'else-body) #t)
                      (cg-indent! -1))
                    (cg-emit p "end"))))))
         (set! codegen-indent saved-indent)
         result))

      ((eq? type 'match)
       (set! match-counter (+ match-counter 1))
       (let ((tmp (string-append "_m_" (number->string match-counter)))
             (value-code (cg-emit-expr port (ast-ref node 'value))))
         (let ((saved-indent codegen-indent))
           (let ((result
                  (with-output-to-string
                    (lambda ()
                      (let ((p (current-output-port)))
                        (display "(function()" p) (newline p)
                        (set! codegen-indent (+ saved-indent 1))
                        (cg-emit p (string-append "  local " tmp " = " value-code))
                        (let ((has-if #f))
                          (for-each
                           (lambda (arm)
                             (let* ((pat (ast-ref arm 'pattern))
                                    (body-code (cg-emit-expr p (ast-ref arm 'body))))
                               (cond
                                 ((eq? (ast-type pat) 'wildcard)
                                  (let ((ind (if has-if "    " "  ")))
                                    (when has-if (cg-emit p "  else"))
                                    (cg-emit p (string-append ind "return " body-code))))
                                 ((eq? (ast-type pat) 'ident)
                                  (let ((ind (if has-if "    " "  ")))
                                    (when has-if (cg-emit p "  else"))
                                    (cg-emit p (string-append ind "local " (ast-ref pat 'name) " = " tmp))
                                    (cg-emit p (string-append ind "return " body-code))))
                                 (else
                                  (let ((pat-code (cg-emit-expr p pat)))
                                    (if has-if
                                        (cg-emit p (string-append "  elseif " tmp " == " pat-code " then"))
                                        (begin
                                          (cg-emit p (string-append "  if " tmp " == " pat-code " then"))
                                          (set! has-if #t)))
                                    (cg-emit p (string-append "    return " body-code)))))))
                           (ast-ref node 'arms))
                          (when has-if (cg-emit p "  end")))
                        (display "end)()" p) (newline p))))))
             (set! codegen-indent saved-indent)
             result))))

      ((eq? type 'placeholder)
       (error 'codegen "placeholder outside pipeline context"))

      ((eq? type 'program)
       (for-each
        (lambda (stmt)
          (let ((line (cg-emit-expr port stmt)))
            (when (not (string=? line ""))
              (cg-emit port line))))
        (ast-ref node 'body))
       "")

      (else
       (error 'codegen (format "Unknown node type: ~s" type))))))

;;; String join helper
(define (string-join lst sep)
  (if (null? lst)
      ""
      (let loop ((rest (cdr lst)) (result (car lst)))
        (if (null? rest)
            result
            (loop (cdr rest) (string-append result sep (car rest)))))))

;;; Overloaded function emission
(define match-counter 0)

(define (cg-emit-overloaded-fn port node)
  (let ((name (ast-ref node 'name))
        (overloads (ast-ref node 'overloads)))
    (if (and (= (length overloads) 1)
             (not (cg-has-literal-params (car overloads))))
        ;; Simple single-overload function
        (let* ((params (map (lambda (p) (ast-ref p 'name))
                            (ast-ref (car overloads) 'params))))
          (cg-emit port (string-append "local function " name "(" (string-join params ", ") ")"))
          (cg-indent! 1)
          (cg-emit-fn-body port (ast-ref (car overloads) 'body) #t)
          (cg-indent! -1)
          (cg-emit port "end")
          "")
        ;; Multi-overload: find catch-all
        (let ((catch-all (let loop ((ol overloads))
                           (cond ((null? ol) #f)
                                 ((not (cg-has-literal-params (car ol))) (car ol))
                                 (else (loop (cdr ol)))))))
          (if catch-all
              ;; Named param dispatch (all same arity)
              (let* ((param-names (map (lambda (p) (ast-ref p 'name))
                                       (ast-ref catch-all 'params)))
                     (sig (string-join param-names ", ")))
                (cg-emit port (string-append "local function " name "(" sig ")"))
                (cg-indent! 1)
                (cg-emit port "if")
                (let ((first #t))
                  (for-each
                   (lambda (ol)
                     (when (cg-has-literal-params ol)
                       (let ((conditions
                              (let lp ((ps (ast-ref ol 'params)) (pn param-names) (acc '()))
                                (if (null? ps)
                                    (reverse! acc)
                                    (if (eq? (ast-ref (car ps) 'is-literal) #t)
                                        (lp (cdr ps) (cdr pn)
                                            (cons (string-append (car pn) " == " (ast-ref (car ps) 'value)) acc))
                                        (lp (cdr ps) (cdr pn) acc))))))
                         (let ((cond-str (if (= (length conditions) 1)
                                            (car conditions)
                                            (string-append "("
                                                           (string-join conditions " and ")
                                                           ")")))
                               (ind (if first "  " "elseif ")))
                           (cg-emit port (string-append ind cond-str " then"))
                           (set! first #f)
                           (cg-indent! 1)
                           (for-each
                            (lambda (ps pn)
                              (unless (eq? (ast-ref ps 'is-literal) #t)
                                (cg-emit port (string-append "local " (ast-ref ps 'name) " = " pn))))
                            (ast-ref ol 'params) param-names)
                           (cg-emit-fn-body port (ast-ref ol 'body) #t)
                           (cg-indent! -1)))))
                   overloads)
                  (cg-emit port "else")
                  (cg-indent! 1)
                  (cg-emit-fn-body port (ast-ref catch-all 'body) #t)
                  (cg-indent! -1)
                  (cg-emit port "end"))
                (cg-indent! -1)
                (cg-emit port "end")
                "")
              ;; Vararg dispatch
              (begin
                (cg-emit port (string-append "local function " name "(...)"))
                (cg-indent! 1)
                (let ((has-chain #f))
                  (for-each
                   (lambda (ol)
                     (if (cg-has-literal-params ol)
                         (let ((conditions
                                (let lp ((ps (ast-ref ol 'params)) (idx 1) (acc '()))
                                  (if (null? ps)
                                      (reverse! acc)
                                      (if (eq? (ast-ref (car ps) 'is-literal) #t)
                                          (lp (cdr ps) (+ idx 1)
                                              (cons (string-append "select(" (number->string idx) ", ...) == "
                                                                   (ast-ref (car ps) 'value))
                                                    acc))
                                          (lp (cdr ps) (+ idx 1) acc))))))
                           (let ((cond-str (if (= (length conditions) 1)
                                              (car conditions)
                                              (string-append "("
                                                             (string-join conditions " and ")
                                                             ")")))
                                 (ind (if has-chain "elseif " "if ")))
                             (cg-emit port (string-append ind cond-str " then"))
                             (set! has-chain #t)))
                         (when has-chain
                           (cg-emit port "else")))
                     (cg-indent! 1)
                     (let ((idx 1))
                       (for-each
                        (lambda (ps)
                          (unless (eq? (ast-ref ps 'is-literal) #t)
                            (cg-emit port (string-append "local " (ast-ref ps 'name)
                                                         " = select(" (number->string idx) ", ...)"))
                            (set! idx (+ idx 1))))
                        (ast-ref ol 'params)))
                     (cg-emit-fn-body port (ast-ref ol 'body) #t)
                     (cg-indent! -1))
                   overloads)
                  (when has-chain
                    (cg-emit port "end")))
                (cg-indent! -1)
                (cg-emit port "end")
                ""))))))

;;; Main entry point
(define (codegen ast)
  (set! codegen-indent 0)
  (set! match-counter 0)
  (let* ((processed (cg-preprocess ast))
         (port (open-output-string)))
    (cg-emit-expr port processed)
    (let ((result (get-output-string port)))
      ;; Strip trailing newline if present
      (if (and (> (string-length result) 0)
               (char=? (string-ref result (- (string-length result) 1)) #\newline))
          (substring result 0 (- (string-length result) 1))
          result))))
