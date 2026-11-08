function spaces(n, s) {
  s = ""
  while (n-- > 0) s = s " "
  return s
}

function visible(s) {
  gsub(/\033\[[0-9;?]*[A-Za-z]/, "", s)
  return length(s)
}

function track(word, t) {
  while (match(word, /\033\[[0-9;]*m/)) {
    t = substr(word, RSTART, RLENGTH)
    active = (t == "\033[m" || t == "\033[0m") ? "" : active t
    word = substr(word, RSTART + RLENGTH)
  }
}

function emit(s) {
  gsub(/\\/, "\\\\", s)
  gsub(/"/, "\\\"", s)
  gsub(/\{/, "{{", s)
  gsub(/\033/, "\\u001b", s)
  printf "%s{\"type\":\"custom\",\"format\":\"%s\"}", (count++ ? "," : ""), s
  rows = count
}

function value_row(line, col, prefix, rest, room, cur, used, gap, word, width) {
  match(line, /\033\[[0-9]+G/)
  col = substr(line, RSTART + 2, RLENGTH - 3) - 1
  prefix = substr(line, 1, RSTART - 1)
  rest = substr(line, RSTART + RLENGTH)

  room = columns - col
  if (room < 10) room = 10

  cur = prefix spaces(col - visible(prefix))
  used = 0
  gap = 0
  active = ""

  while (rest != "") {
    if (match(rest, /^ +/)) {
      gap = RLENGTH
      rest = substr(rest, RLENGTH + 1)
      continue
    }
    match(rest, /^[^ ]+/)
    word = substr(rest, 1, RLENGTH)
    rest = substr(rest, RLENGTH + 1)
    width = visible(word)

    if (used > 0 && used + gap + width > room) {
      emit(cur "\033[m")
      cur = spaces(col) active
      used = 0
      gap = 0
    }

    cur = cur spaces(gap) word
    used += gap + width
    gap = 0
    track(word)
  }
  emit(cur "\033[m")
}

$0 == "" {
  printf "%s\"break\"", (count++ ? "," : "")
  next
}

/\033\[[0-9]+G/ {
  value_row($0)
  next
}

{
  emit($0)
}

END {
  printf "\n%d\n", rows
}
