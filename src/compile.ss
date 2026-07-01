;;; Compile .ss files to .so, skipping files that are already up to date
(import (chezscheme))
(define *root* (or (getenv "VENUS_ROOT") (current-directory)))
(parameterize ((current-directory *root*))
  (library-directories (list (string-append *root* "/src") "."))
  (for-each (lambda (f)
              (let* ((ss-path (string-append "src/" f))
                     (so-path (string-append "src/" (path-root f) ".so"))
                     (so-time (lambda (p)
                               (time-second (file-modification-time p))))
                     (needs-compile (or (not (file-exists? so-path))
                                        (> (so-time ss-path) (so-time so-path)))))
                (when needs-compile
                  (compile-file ss-path))))
            '("lexer.ss" "table.ss" "list.ss" "string.ss" "math.ss" "map.ss" "vector.ss"
              "parser.ss" "codegen.ss" "runtime.ss" "builtins.ss")))
