fn flat_map(list, f) {
  List.reduce(list, fn(acc, item) {
    List.each(f(item), fn(v) { List.add(acc, v) })
    acc
  }, [])
}

fn zip(a, b) {
  let len = Math.min(List.len(a), List.len(b))
  let result = []
  List.each(List.range(1, len), fn(val, i) {
    List.add(result, [List.get(a, i), List.get(b, i)])
  })
  result
}

fn take_while(list, f) {
  let stopped = [false]
  List.reduce(list, fn(acc, item) {
    if List.get(stopped, 1) {
      acc
    } else if !f(item) {
      List.add(stopped, true)
      acc
    } else {
      List.add(acc, item)
      acc
    }
  }, [])
}

fn drop_while(list, f) {
  let dropping = [true]
  List.reduce(list, fn(acc, item) {
    if List.get(dropping, 1) {
      if !f(item) {
        List.add(dropping, false)
        List.add(acc, item)
      }
      acc
    } else {
      List.add(acc, item)
      acc
    }
  }, [])
}

fn find(list, f) {
  let result = [nil]
  let found = [false]
  List.each(list, fn(item, idx) {
    if !List.get(found, 1) and f(item) {
      List.add(result, item)
      List.add(found, true)
    }
  })
  List.get(result, 1)
}

fn any(list, f) {
  find(list, f) != nil
}

fn all(list, f) {
  !any(list, fn(x) { !f(x) })
}

export {
  flat_map -> flat_map,
  zip -> zip,
  take_while -> take_while,
  drop_while -> drop_while,
  flatten -> flatten,
  reverse -> reverse,
  find -> find,
  any -> any,
  all -> all
}
