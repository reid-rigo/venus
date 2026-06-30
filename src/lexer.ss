;;; Venus Lexer for Chez Scheme
;;; Tokenizes .vs source into a vector of #(type value) pairs.

(define *tok-number*    'number)
(define *tok-string*    'string)
(define *tok-ident*     'ident)
(define *tok-pipe*      'pipe)
(define *tok-lparen*    'lparen)
(define *tok-rparen*    'rparen)
(define *tok-plus*      'plus)
(define *tok-minus*     'minus)
(define *tok-star*      'star)
(define *tok-slash*     'slash)
(define *tok-eq*        'eq)
(define *tok-eqeq*      'eqeq)
(define *tok-bangeq*    'bangeq)
(define *tok-bang*      'bang)
(define *tok-lt*        'lt)
(define *tok-gt*        'gt)
(define *tok-le*        'le)
(define *tok-ge*        'ge)
(define *tok-comma*     'comma)
(define *tok-dot*       'dot)
(define *tok-qdot*      'qdot)
(define *tok-newline*   'newline)
(define *tok-let*       'let)
(define *tok-fn*        'fn)
(define *tok-match*     'match)
(define *tok-arrow*     'arrow)
(define *tok-lbrace*    'lbrace)
(define *tok-rbrace*    'rbrace)
(define *tok-lbracket*  'lbracket)
(define *tok-rbracket*  'rbracket)
(define *tok-underscore* 'underscore)
(define *tok-if*        'if)
(define *tok-else*      'else)
(define *tok-and*       'and)
(define *tok-or*        'or)
(define *tok-nil*       'nil)
(define *tok-true*      'true)
(define *tok-false*     'false)
(define *tok-import*    'import)
(define *tok-export*    'export)
(define *tok-eof*       'eof)

(define (tok type val) (vector type val))
(define (tok-type t) (vector-ref t 0))
(define (tok-value t) (vector-ref t 1))

(define (char-alpha? c)
  (and c (or (char-alphabetic? c) (char=? c #\_))))

(define (char-alnum? c)
  (and c (or (char-alphabetic? c) (char-numeric? c) (char=? c #\_))))

(define (char-digit? c)
  (and c (char-numeric? c)))

(define (keyword-type word)
  (cond
    [(string=? word "let")    *tok-let*]
    [(string=? word "fn")     *tok-fn*]
    [(string=? word "match")  *tok-match*]
    [(string=? word "if")     *tok-if*]
    [(string=? word "else")   *tok-else*]
    [(string=? word "and")    *tok-and*]
    [(string=? word "or")     *tok-or*]
    [(string=? word "nil")    *tok-nil*]
    [(string=? word "true")   *tok-true*]
    [(string=? word "false")  *tok-false*]
    [(string=? word "import") *tok-import*]
    [(string=? word "export") *tok-export*]
    [else #f]))

(define (single-token-type c)
  (case c
    ((#\() *tok-lparen*)   ((#\)) *tok-rparen*)
    ((#\+) *tok-plus*)     ((#\*) *tok-star*)
    ((#\/) *tok-slash*)    ((#\,) *tok-comma*)
    ((#\{) *tok-lbrace*)   ((#\}) *tok-rbrace*)
    ((#\[) *tok-lbracket*) ((#\]) *tok-rbracket*)
    ((#\_) *tok-underscore*)
    (else #f)))

(define (tokenize source)
  (let ([len (string-length source)]
        [pos 0])
    (define (peek off)
      (let ([i (+ pos off)])
        (if (>= i len) #f (string-ref source i))))
    (define (advance!)
      (let ([c (string-ref source pos)])
        (set! pos (+ pos 1))
        c))
    (define (char=?/safe a b)
      (and a b (char=? a b)))
    (define (skip-ws!)
      (let loop ()
        (when (< pos len)
          (let ([c (peek 0)])
            (cond
              [(or (char=? c #\space) (char=? c #\tab) (char=? c #\return))
               (advance!) (loop)]
              [(and (char=? c #\/) (< (+ pos 1) len) (char=? (peek 1) #\/))
               (let skip ()
                 (when (< pos len)
                   (if (char=? (advance!) #\newline) #f (skip))))
               (loop)]
              [else #f])))))
    (define (read-number)
      (let ([start pos])
        (let loop ()
          (when (char-digit? (peek 0)) (advance!) (loop)))
        (when (and (char=?/safe (peek 0) #\.) (char-digit? (peek 1)))
          (advance!)
          (let loop ()
            (when (char-digit? (peek 0)) (advance!) (loop))))
        (substring source start pos)))
    (define (read-interp-expr)
      (let ([buf (open-output-string)] [depth 1] [result ""])
        (let loop ()
          (when (< pos len)
            (let ([c (advance!)])
              (cond
                [(char=? c #\{)
                 (set! depth (+ depth 1))
                 (write-char c buf) (loop)]
                [(char=? c #\})
                 (set! depth (- depth 1))
                 (if (= depth 0)
                     (set! result (get-output-string buf))
                     (begin (write-char c buf) (loop)))]
                [(or (char=? c #\") (char=? c #\'))
                 (write-char c buf)
                 (let skip-str ()
                   (when (< pos len)
                     (let ([sc (advance!)])
                       (write-char sc buf)
                       (cond
                         [(char=? sc #\\)
                          (when (< pos len) (write-char (advance!) buf))
                          (skip-str)]
                         [(char=? sc c) #f]
                         [else (skip-str)]))))
                 (loop)]
                [else (write-char c buf) (loop)]))))
        result))
    (define (read-string)
      (let* ([start pos] [qc (advance!)])
        (if (char=? qc #\')
            (begin
              (let loop ()
                (when (< pos len)
                  (let ([c (advance!)])
                    (cond
                      [(char=? c #\\) (advance!) (loop)]
                      [(char=? c qc) #f]
                      [else (loop)]))))
              (substring source start pos))
            (let ([parts '()] [buf (open-output-string)])
              (define (flush!)
                (let ([s (get-output-string buf)])
                  (when (> (string-length s) 0)
                    (set! parts (cons (cons 'text s) parts))
                    (set! buf (open-output-string)))))
              (let loop ()
                (when (< pos len)
                  (let ([c (advance!)])
                    (cond
                      [(char=? c #\\)
                       (write-char c buf)
                       (when (< pos len) (write-char (advance!) buf))
                       (loop)]
                      [(and (char=? c #\#) (char=? (peek 0) #\{))
                       (flush!)
                       (advance!)
                       (set! parts (cons (cons 'expr (read-interp-expr)) parts))
                       (loop)]
                      [(char=? c qc)
                       (flush!)
                       (set! parts (reverse! parts))
                       (if (ormap (lambda (p) (eq? (car p) 'expr)) parts)
                           parts
                           (substring source start pos))]
                      [else (write-char c buf) (loop)]))))))))
    (define (read-multiline-string)
      (let* ([start pos])
        (advance!) (advance!) (advance!)
        (let ([parts '()] [buf (open-output-string)])
          (define (flush!)
            (let ([s (get-output-string buf)])
              (when (> (string-length s) 0)
                (set! parts (cons (cons 'text s) parts))
                (set! buf (open-output-string)))))
          (let loop ()
            (when (< pos len)
              (let ([c (advance!)])
                (cond
                  [(and (char=? c #\#) (char=? (peek 0) #\{))
                   (flush!)
                   (advance!)
                   (set! parts (cons (cons 'expr (read-interp-expr)) parts))
                   (loop)]
                  [(and (char=? c #\")
                        (char=? (peek 0) #\")
                        (char=? (peek 1) #\"))
                   (flush!)
                   (advance!) (advance!)
                   (set! parts (reverse! parts))
                   (if (ormap (lambda (p) (eq? (car p) 'expr)) parts)
                       parts
                       (substring source start pos))]
                  [else (write-char c buf) (loop)])))))))
    ;; main loop
    (let loop ([tokens '()])
      (skip-ws!)
      (if (>= pos len)
          (reverse! (cons (tok *tok-eof* #f) tokens))
          (let ([c (peek 0)])
            (if (not c)
                (loop (cons (tok *tok-eof* #f) tokens))
                (let ([c2 (peek 1)])
                  (cond
              [(char=? c #\newline)
               (advance!)
               (loop (cons (tok *tok-newline* "\\n") tokens))]
              [(and (char=? c #\|) (char=?/safe c2 #\>))
               (advance!) (advance!)
               (loop (cons (tok *tok-pipe* "|>") tokens))]
               [(single-token-type c) => (lambda (type)
                                          (advance!)
                                          (loop (cons (tok type (string c)) tokens)))]
               [(and (char=? c #\-) (char=?/safe c2 #\>))
               (advance!) (advance!)
               (loop (cons (tok *tok-arrow* "->") tokens))]
              [(char=? c #\-)
               (advance!)
               (loop (cons (tok *tok-minus* "-") tokens))]
               [(and (char=? c #\=) (char=?/safe c2 #\=))
               (advance!) (advance!)
               (loop (cons (tok *tok-eqeq* "==") tokens))]
              [(char=? c #\=)
               (advance!)
               (loop (cons (tok *tok-eq* "=") tokens))]
              [(and (char=? c #\!) (char=?/safe c2 #\=))
               (advance!) (advance!)
               (loop (cons (tok *tok-bangeq* "!=") tokens))]
              [(char=? c #\!)
               (advance!)
               (loop (cons (tok *tok-bang* "!") tokens))]
              [(and (char=? c #\<) (char=?/safe c2 #\=))
               (advance!) (advance!)
               (loop (cons (tok *tok-le* "<=") tokens))]
              [(char=? c #\<)
               (advance!)
               (loop (cons (tok *tok-lt* "<") tokens))]
              [(and (char=? c #\>) (char=?/safe c2 #\=))
               (advance!) (advance!)
               (loop (cons (tok *tok-ge* ">=") tokens))]
              [(char=? c #\>)
               (advance!)
               (loop (cons (tok *tok-gt* ">") tokens))]
               [(and (char=? c #\?) (char=?/safe c2 #\.))
               (advance!) (advance!)
               (loop (cons (tok *tok-qdot* "?.") tokens))]
              [(char=? c #\.)
               (if (and c2 (char-digit? c2))
                   (loop (cons (tok *tok-number* (read-number)) tokens))
                   (begin (advance!)
                          (loop (cons (tok *tok-dot* ".") tokens))))]
              [(and (char=? c #\") (char=?/safe c2 #\") (char=?/safe (peek 2) #\"))
               (loop (cons (tok *tok-string* (read-multiline-string)) tokens))]
              [(or (char=? c #\") (char=? c #\'))
               (loop (cons (tok *tok-string* (read-string)) tokens))]
              [(char-digit? c)
               (loop (cons (tok *tok-number* (read-number)) tokens))]
               [(char-alpha? c)
               (let* ([start pos]
                      [_ (let scan ()
                           (when (char-alnum? (peek 0))
                             (advance!) (scan)))]
                      [word (substring source start pos)]
                      [kw (keyword-type word)])
                 (loop (cons (tok (or kw *tok-ident*) word) tokens)))]
                [else
                 (error 'tokenize "Unexpected character:" c)]))))))))
