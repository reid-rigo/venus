fn merge(a, b) {
  let result = {}
  Table.each(a, fn(v, k) { Table.set(result, k, v) })
  Table.each(b, fn(v, k) { Table.set(result, k, v) })
  result
}

fn invert(m) {
  let result = {}
  Table.each(m, fn(v, k) { Table.set(result, v, k) })
  result
}

fn pick(m, keys) {
  let result = {}
  List.each(keys, fn(k) {
    if Table.has(m, k) {
      Table.set(result, k, Table.get(m, k))
    }
  })
  result
}

fn omit(m, keys) {
  let result = {}
  Table.each(m, fn(v, k) {
    let is_excluded = List.any(keys, fn(exclude) { k == exclude })
    if !is_excluded {
      Table.set(result, k, v)
    }
  })
  result
}

fn map_keys(m, f) {
  let result = {}
  Table.each(m, fn(v, k) { Table.set(result, f(k), v) })
  result
}

fn filter(m, f) {
  let result = {}
  Table.each(m, fn(v, k) {
    if f(v, k) { Table.set(result, k, v) }
  })
  result
}

fn to_list(m) {
  let result = []
  Table.each(m, fn(v) { List.add(result, v) })
  result
}

export {
  merge -> merge,
  invert -> invert,
  pick -> pick,
  omit -> omit,
  map_keys -> map_keys,
  filter -> filter,
  to_list -> to_list
}
