#!/usr/bin/env bash
# Slots reporter, start gate (can-start <builder>) and DeepSeek spend tracker (DECISIONS 2026-10-23, D1 2026-10-27)
set -uo pipefail
. "$(dirname "$0")/lib.sh"
dir="$(wt_dir)"

if [ "${1:-}" = "append-spend" ]; then
  log="$2"; task="$3"; in_rate="$4"; out_rate="$5"; csv="${6:-$dir/cf_spend.csv}"
  $py -c '
import sys, re, os, datetime
log_path, task, in_rate, out_rate, csv_path = sys.argv[1:6]
in_r = float(in_rate)
out_r = float(out_rate)
date_str = datetime.date.today().isoformat()
text = ""
for path in (log_path[:-4] + ".build.log" if log_path.endswith(".log") else "", log_path):  # fix pass overwrote .log
    if path and os.path.isfile(path):
        text += open(path, encoding="utf-8", errors="replace").read() + "\n"

def parse_tokens(txt):
    ins = re.findall(r"\"(?:input|input_tokens|prompt_tokens)\":\s*(\d+)", txt)  # one per request: sum them
    outs = re.findall(r"\"(?:output|output_tokens|completion_tokens)\":\s*(\d+)", txt)
    if ins and outs:
        return sum(map(int, ins)), sum(map(int, outs))
    t_in = re.findall(r"(?:input[_\s]+tokens?|prompt[_\s]+tokens?)\s*[:=]\s*(\d[\d,]*)", txt, re.I)  # a build and a fix pass
    t_out = re.findall(r"(?:output[_\s]+tokens?|completion[_\s]+tokens?)\s*[:=]\s*(\d[\d,]*)", txt, re.I)
    if t_in and t_out:
        return sum(int(v.replace(",", "")) for v in t_in), sum(int(v.replace(",", "")) for v in t_out)
    m_in = re.search(r"(\d[\d,]*)\s*(?:input|prompt)\s*tokens?", txt, re.I)
    m_out = re.search(r"(\d[\d,]*)\s*(?:output|completion)\s*tokens?", txt, re.I)
    if m_in and m_out:
        return int(m_in.group(1).replace(",", "")), int(m_out.group(1).replace(",", ""))
    m = re.search(r"tokens?[:\s]+(\d[\d,]*)\s*input[,\s]+(\d[\d,]*)\s*output", txt, re.I)
    if m:
        return int(m.group(1).replace(",", "")), int(m.group(2).replace(",", ""))
    return None, None

in_tok, out_tok = parse_tokens(text)
if in_tok is not None and out_tok is not None:
    usd = (in_tok * in_r + out_tok * out_r) / 1000000.0
    line = f"{date_str},{task},{in_tok},{out_tok},{usd:.2f}"
else:
    line = f"{date_str},{task},,,?"

header_needed = not os.path.exists(csv_path) or os.path.getsize(csv_path) == 0
os.makedirs(os.path.dirname(os.path.abspath(csv_path)), exist_ok=True)
with open(csv_path, "a", encoding="utf-8", newline="\n") as f:
    if header_needed:
        f.write("date,task,input_tokens,output_tokens,usd\n")
    f.write(line + "\n")
' "$log" "$task" "$in_rate" "$out_rate" "$csv"
  exit 0
fi

now=$(date +%s)
count_agy=0
count_cf=0
count_oc=0
free="$(free_mb)"

for res in "$dir"/*.result; do
  [ -e "$res" ] || continue
  task="$(basename "$res" .result)"
  line1="$(head -n 1 "$res" 2>/dev/null || true)"
  first_word="$(echo "$line1" | awk '{print $1}')"
  [ "$first_word" = "RUNNING" ] || continue

  time_val="$(echo "$line1" | awk '{print $2}')"
  step_val="$(echo "$line1" | cut -d' ' -f3-)"

  line2="$(sed -n '2p' "$res" 2>/dev/null || true)"
  builder=""
  if [[ "$line2" =~ ^builder[[:space:]]+([a-zA-Z0-9_-]+) ]]; then
    builder="${BASH_REMATCH[1]}"
  fi
  if [ -z "$builder" ]; then  # results from before the builder line: guess from the branch prefix
    case "$(git -C "$dir/$task" rev-parse --abbrev-ref HEAD 2>/dev/null)" in gemini/*) builder=agy ;; *) builder=oc ;; esac
  fi

  pid="$(sed -n 's/^pid //p' "$res" | head -n 1)"
  if [ -n "$pid" ] && ! kill -0 "$pid" 2> /dev/null; then  # the pipeline died without finishing its .result
    echo "$builder $task $step_val since $time_val DEAD"; continue
  fi
  log="$dir/$task.log"
  stale=0
  if [ -f "$log" ]; then
    mtime=$(stat -c %Y "$log" 2>/dev/null || echo "$now")
  else
    mtime=$(stat -c %Y "$res" 2>/dev/null || echo "$now")
  fi
  diff=$((now - mtime))
  if [ $diff -ge 7200 ]; then
    stale=1
  fi

  if [ $stale -eq 1 ]; then
    echo "$builder $task $step_val since $time_val STALE?"
  else
    echo "$builder $task $step_val since $time_val"
    case "$builder" in
      agy) count_agy=$((count_agy + 1)) ;;
      cf)  count_cf=$((count_cf + 1)) ;;
      oc)  count_oc=$((count_oc + 1)) ;;
    esac
  fi
done

count_godot=$((count_agy + count_cf))
echo "agy $count_agy/$CAP_AGY  cf $count_cf/$CAP_CF  oc $count_oc/$CAP_OC"
echo "godot $count_godot/$CAP_GODOT  free ${free} MB (floor $MIN_FREE_MB)"

if [ "${1:-}" = "can-start" ]; then  # slots.sh can-start <agy|cf|oc>: exit 0 only when a run of that kind may start
  case "${2:-}" in
    oc) [ $count_oc -lt $CAP_OC ] || { echo "REFUSED: text run slot busy"; exit 1; } ;;
    agy|cf) [ $count_godot -lt $CAP_GODOT ] || { echo "REFUSED: godot $count_godot/$CAP_GODOT"; exit 1; } ;;
    *) echo "can-start: builder agy|cf|oc"; exit 2 ;;
  esac
  [ "$2" = oc ] || [ "$free" -ge "$MIN_FREE_MB" ] || { echo "REFUSED: memory ${free} MB free < $MIN_FREE_MB"; exit 1; }
  exit 0
fi

spend_csv="$dir/cf_spend.csv"
month="$(date +%Y-%m)"
spend="$($py -c '
import sys, csv, os
total = 0.0
path = sys.argv[1]
month = sys.argv[2]
if os.path.isfile(path):
    with open(path, encoding="utf-8", errors="replace") as f:
        r = csv.reader(f)
        for row in r:
            if len(row) >= 5 and row[0].startswith(month):
                val = row[4].strip()
                if val and val != "?":
                    try:
                        total += float(val)
                    except ValueError:
                        pass
print(f"{total:.2f}")
' "$spend_csv" "$month")"

echo "cf spend this month: \$$spend"

if [ $count_agy -gt $CAP_AGY ] || [ $count_cf -gt $CAP_CF ] || [ $count_oc -gt $CAP_OC ] || [ $count_godot -gt $CAP_GODOT ]; then
  exit 1
fi
exit 0
