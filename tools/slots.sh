#!/usr/bin/env bash
CAP_AGY=${CAP_AGY:-0}; CAP_CF=${CAP_CF:-3}; CAP_OC=${CAP_OC:-0}  # env overrides for tests
# Slots reporter and DeepSeek spend tracker (DECISIONS 2026-10-23)
set -uo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
root="$(git rev-parse --show-toplevel 2>/dev/null || dirname "$here")"

if [ -n "${GAME_WT_DIR:-}" ]; then
  dir="$GAME_WT_DIR"
elif [ -d "$(dirname "$root")/game-wt" ]; then
  dir="$(dirname "$root")/game-wt"
elif [ -d "$root/.." ] && [ "$(basename "$(dirname "$root")")" = "game-wt" ]; then
  dir="$(dirname "$root")"
else
  dir="$(dirname "$root")/game-wt"
fi

py=python; $py -c "" >/dev/null 2>&1 || py=python3

if [ "${1:-}" = "append-spend" ]; then
  log="$2"; task="$3"; in_rate="$4"; out_rate="$5"; csv="${6:-$dir/cf_spend.csv}"
  $py -c '
import sys, re, os, datetime
log_path, task, in_rate, out_rate, csv_path = sys.argv[1:6]
in_r = float(in_rate)
out_r = float(out_rate)
date_str = datetime.date.today().isoformat()
text = ""
if os.path.isfile(log_path):
    text = open(log_path, encoding="utf-8", errors="replace").read()

def parse_tokens(txt):
    ins = re.findall(r"\"(?:input|input_tokens|prompt_tokens)\":\s*(\d+)", txt)  # one per request: sum them
    outs = re.findall(r"\"(?:output|output_tokens|completion_tokens)\":\s*(\d+)", txt)
    if ins and outs:
        return sum(map(int, ins)), sum(map(int, outs))
    m_in = re.search(r"(?:input[_\s]+tokens?|prompt[_\s]+tokens?)\s*[:=]\s*(\d[\d,]*)", txt, re.I)
    m_out = re.search(r"(?:output[_\s]+tokens?|completion[_\s]+tokens?)\s*[:=]\s*(\d[\d,]*)", txt, re.I)
    if m_in and m_out:
        return int(m_in.group(1).replace(",", "")), int(m_out.group(1).replace(",", ""))
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

echo "agy $count_agy/$CAP_AGY  cf $count_cf/$CAP_CF  oc $count_oc/$CAP_OC"

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

if [ $count_agy -gt $CAP_AGY ] || [ $count_cf -gt $CAP_CF ] || [ $count_oc -gt $CAP_OC ]; then
  exit 1
fi
exit 0
