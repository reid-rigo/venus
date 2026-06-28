fn reverse(s) {
  let chars = String.split(s, "")
  let reversed = List.reverse(chars)
  List.join(reversed, "")
}

fn repeat_str(s, n) {
  let result = [""]
  List.each(List.range(0, n - 1), fn(val, idx) {
    List.add(result, s)
  })
  List.join(result, "")
}

fn pad(s, len, char) {
  let slen = String.len(s)
  let enough = slen >= len
  if enough {
    s
  } else {
    let padding = repeat_str(char, len - slen)
    List.join([s, padding], "")
  }
}

fn pad_left(s, len, char) {
  let slen = String.len(s)
  let enough = slen >= len
  if enough {
    s
  } else {
    let padding = repeat_str(char, len - slen)
    List.join([padding, s], "")
  }
}

fn replace(s, old, new) {
  let parts = String.split(s, old)
  List.join(parts, new)
}

fn chars(s) {
  String.split(s, "")
}

fn is_empty(s) {
  String.len(s) == 0
}

export {
  reverse -> reverse,
  repeat_str -> repeat_str,
  pad -> pad,
  pad_left -> pad_left,
  replace -> replace,
  chars -> chars,
  is_empty -> is_empty
}
