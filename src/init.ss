;;; Venus init — loads all modules into the heap
;;; Used by the C harness to build a pre-compiled heap image.

(import (chezscheme))
(define *root* (or (getenv "VENUS_ROOT") (current-directory)))
(library-directories (list (string-append *root* "/src") "."))

(define (load-ss name)
  (let ((so-path (string-append *root* "/src/" name ".so"))
        (ss-path (string-append *root* "/src/" name ".ss")))
    (if (file-exists? so-path)
        (load so-path)
        (load ss-path))))

;; Transitive dependency order matters
(load-ss "lexer")
(load-ss "table")
(load-ss "list")
(load-ss "string")
(load-ss "math")
(load-ss "map")
(load-ss "vector")
(load-ss "parser")
(load-ss "codegen")
(load-ss "runtime")
(load-ss "builtins")

;; Load Venus standard library extensions into the interaction environment.
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

;; builtins loaded above via load-ss
