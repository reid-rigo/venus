(import (srfi :146))
(import (srfi :128))

(define *map-comparator* (make-default-comparator))

(define (Map-make . args)
  (if (null? args)
      (mapping *map-comparator*)
      (apply mapping *map-comparator* args)))

(define (Map-has m k) (mapping-contains? m k))
(define (Map-get m k) (mapping-ref/default m k venus-nil))
(define (Map-set m k v) (mapping-set m k v))
(define (Map-remove m k) (mapping-delete m k))
(define (Map-len m) (mapping-size m))

(define (Map-keys m)
  (list->venus-list (mapping-keys m)))

(define (Map-values m)
  (list->venus-list (mapping-values m)))

(define (Map-each m f)
  (mapping-for-each (lambda (k v) (f v k)) m)
  venus-nil)

(define (Map-map m f)
  (list->venus-list (mapping-map->list (lambda (k v) (f v)) m)))

(define (Map-filter m pred)
  (mapping-filter (lambda (k v) (pred v k)) m))

(define (Map-merge m1 m2)
  (mapping-union m2 m1))

(define (Map-to_list m)
  (list->venus-list
    (mapping-fold (lambda (k v acc)
                    (cons (venus-list k v) acc))
                  '() m)))
