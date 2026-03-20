#!/usr/bin/env bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════════
# Clawfather 一键卸载脚本
# 卸载 OpenClaw 并生成 Wrapped 风格的使用报告
# https://www.clawfather.cn
# ═══════════════════════════════════════════════════════════════════════════════

VERSION="1.0.0"

# ─── CLI Flags ────────────────────────────────────────────────────────────────

OPT_DRY_RUN=false
OPT_YES=false
OPT_KEEP_CONFIG=false
OPT_WRAPPED_ONLY=false
OPT_LANG="zh"
OPT_NO_COLOR=false

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --dry-run)       OPT_DRY_RUN=true ;;
      --yes|-y|--non-interactive) OPT_YES=true ;;
      --keep-config)   OPT_KEEP_CONFIG=true ;;
      --wrapped-only)  OPT_WRAPPED_ONLY=true ;;
      --lang=*)        OPT_LANG="${1#*=}" ;;
      --no-color)      OPT_NO_COLOR=true ;;
      --version)       echo "clawfather-uninstall v${VERSION}"; exit 0 ;;
      --help|-h)       print_usage; exit 0 ;;
      *) echo "Unknown option: $1"; print_usage; exit 1 ;;
    esac
    shift
  done
}

print_usage() {
  cat <<'USAGE'
Clawfather 一键卸载脚本 — OpenClaw Wrapped Uninstaller

用法: bash uninstall.sh [选项]

选项:
  --dry-run          只生成报告，不执行卸载
  --yes, -y          跳过确认提示
  --keep-config      保留配置和工作区文件
  --wrapped-only     只看 Wrapped 报告，不卸载
  --lang=zh|en       语言 (默认 zh)
  --no-color         纯文本输出
  --version          显示版本
  --help, -h         显示帮助

示例:
  bash uninstall.sh                     # 交互式卸载 + Wrapped
  bash uninstall.sh --wrapped-only      # 只看报告，不卸载
  bash uninstall.sh --dry-run           # 预览将删除的内容
  bash uninstall.sh --yes --lang=en     # 非交互式英文卸载
USAGE
}

# ─── Color / Output Helpers ───────────────────────────────────────────────────

setup_colors() {
  if [[ "$OPT_NO_COLOR" == true ]] || [[ ! -t 1 ]]; then
    RST="" BLD="" DIM=""
    RED="" GRN="" YLW="" BLU="" MAG="" CYN="" WHT="" GRY=""
  else
    RST=$'\e[0m'  BLD=$'\e[1m'  DIM=$'\e[2m'
    RED=$'\e[31m' GRN=$'\e[32m' YLW=$'\e[33m' BLU=$'\e[34m'
    MAG=$'\e[35m' CYN=$'\e[36m' WHT=$'\e[37m' GRY=$'\e[90m'
  fi
}

info()  { echo "${CYN}ℹ${RST}  $*"; }
ok()    { echo "${GRN}✓${RST}  $*"; }
warn()  { echo "${YLW}⚠${RST}  $*"; }
err()   { echo "${RED}✗${RST}  $*" >&2; }

confirm() {
  local prompt="$1"
  if [[ "$OPT_YES" == true ]]; then return 0; fi
  echo ""
  read -rp "${BLD}${prompt}${RST} [y/N] " answer </dev/tty
  [[ "$answer" =~ ^[Yy]$ ]]
}

# ─── i18n ─────────────────────────────────────────────────────────────────────

t() {
  local key="$1"
  if [[ "$OPT_LANG" == "en" ]]; then
    case "$key" in
      title)            echo "OpenClaw Usage Summary" ;;
      days)             echo "Days Together" ;;
      sessions)         echo "Conversations" ;;
      messages)         echo "Messages" ;;
      tokens)           echo "Tokens Used" ;;
      cost)             echo "Est. Cost" ;;
      agents)           echo "Agents" ;;
      skills)           echo "Skills" ;;
      channels)         echo "Channels" ;;
      peak_hour)        echo "Peak Hours" ;;
      fav_model)        echo "Favorite Model" ;;
      night_owl)        echo "Night Owl" ;;
      early_bird)       echo "Early Bird" ;;
      steady)           echo "Steady Worker" ;;
      confirm_uninstall) echo "Proceed with uninstall?" ;;
      uninstall_done)   echo "OpenClaw has been uninstalled. Farewell!" ;;
      scanning)         echo "Scanning local data..." ;;
      no_data)          echo "No OpenClaw data found at" ;;
      farewell_quote)   echo "late-night conversations with AI" ;;
      farewell_power)   echo "You've been a power user." ;;
      farewell_thanks)  echo "" ;;
      disclaimer)       echo "* Data is approximate and for reference only." ;;
      will_remove)      echo "The following will be removed:" ;;
      kept)             echo "(kept)" ;;
      skip_dry)         echo "[DRY RUN] No files were deleted." ;;
      activity)         echo "24h Activity" ;;
      *)                echo "$key" ;;
    esac
  else
    case "$key" in
      title)            echo "OpenClaw 使用总结" ;;
      days)             echo "相伴时光" ;;
      sessions)         echo "会话总数" ;;
      messages)         echo "消息总数" ;;
      tokens)           echo "Token 消耗" ;;
      cost)             echo "估算费用" ;;
      agents)           echo "智能体" ;;
      skills)           echo "Skills" ;;
      channels)         echo "渠道" ;;
      peak_hour)        echo "最活跃时段" ;;
      fav_model)        echo "最爱模型" ;;
      night_owl)        echo "夜猫子" ;;
      early_bird)       echo "早起鸟" ;;
      steady)           echo "稳定输出型" ;;
      confirm_uninstall) echo "确认卸载 OpenClaw？" ;;
      uninstall_done)   echo "OpenClaw 已卸载完成，后会有期！" ;;
      scanning)         echo "正在扫描本地数据..." ;;
      no_data)          echo "未找到 OpenClaw 数据：" ;;
      farewell_quote)   echo "次与 AI 的对话" ;;
      farewell_power)   echo "你是一位超级用户。" ;;
      farewell_thanks)  echo "" ;;
      disclaimer)       echo "* 以上数据仅供参考娱乐，实际请以官方数据为准。" ;;
      will_remove)      echo "以下内容将被删除：" ;;
      kept)             echo "（已保留）" ;;
      skip_dry)         echo "[预演模式] 未删除任何文件。" ;;
      activity)         echo "24h 活跃度" ;;
      *)                echo "$key" ;;
    esac
  fi
}

# ─── Utility ──────────────────────────────────────────────────────────────────

OPENCLAW_STATE="${OPENCLAW_STATE_DIR:-$HOME/.openclaw}"

has_cmd()  { command -v "$1" >/dev/null 2>&1; }
is_macos() { [[ "$(uname -s)" == "Darwin" ]]; }
is_linux() { [[ "$(uname -s)" == "Linux" ]]; }

validate_state_dir() {
  local dir="$1"
  local resolved
  resolved=$(cd "$dir" 2>/dev/null && pwd -P) || resolved="$dir"

  local blocked=("/" "/bin" "/boot" "/dev" "/etc" "/lib" "/lib64" "/opt" "/proc"
    "/root" "/run" "/sbin" "/srv" "/sys" "/tmp" "/usr" "/var"
    "$HOME" "$HOME/Desktop" "$HOME/Documents" "$HOME/Downloads" "$HOME/Pictures"
    "$HOME/Music" "$HOME/Videos" "$HOME/Library")

  for b in "${blocked[@]}"; do
    [[ -z "$b" ]] && continue
    if [[ "$resolved" == "$b" ]]; then
      err "SAFETY: state dir '$dir' (resolved: '$resolved') matches blocked path '$b'. Aborting."
      exit 1
    fi
  done

  local base
  base=$(basename "$resolved")
  if [[ "$base" != .openclaw* ]]; then
    err "SAFETY: state dir basename '$base' does not start with '.openclaw'. Aborting."
    exit 1
  fi
}

format_number() {
  local n="${1:-0}"
  if [[ "$n" -ge 1000000 ]]; then
    awk "BEGIN { printf \"%.1fM\", $n/1000000 }"
  elif [[ "$n" -ge 1000 ]]; then
    awk "BEGIN { printf \"%.1fK\", $n/1000 }"
  else
    echo "$n"
  fi
}

# Convert any timestamp (epoch ms, epoch s, or ISO 8601) to epoch seconds
to_epoch_s() {
  local raw="$1"
  [[ -z "$raw" || "$raw" == "null" || "$raw" == "0" ]] && { echo 0; return; }

  if [[ "$raw" =~ ^[0-9]+$ ]]; then
    if [[ ${#raw} -gt 10 ]]; then
      echo $(( raw / 1000 ))
    else
      echo "$raw"
    fi
  elif [[ "$raw" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2} ]]; then
    if is_macos; then
      date -j -f "%Y-%m-%dT%H:%M:%S" "${raw%%.*}" "+%s" 2>/dev/null ||
        date -j -f "%Y-%m-%d" "${raw:0:10}" "+%s" 2>/dev/null ||
        echo 0
    else
      date -d "$raw" "+%s" 2>/dev/null || echo 0
    fi
  else
    echo 0
  fi
}

format_date() {
  local epoch_s
  epoch_s=$(to_epoch_s "$1")
  [[ "$epoch_s" -eq 0 ]] && { echo "?"; return; }
  if is_macos; then
    date -r "$epoch_s" "+%Y.%m.%d" 2>/dev/null || echo "?"
  else
    date -d "@$epoch_s" "+%Y.%m.%d" 2>/dev/null || echo "?"
  fi
}

today_str() { date "+%Y.%m.%d"; }
now_ts()    { date "+%s"; }

# Extract first numeric value after a key in a JSON-ish line (no jq needed)
grep_json_num() {
  local key="$1"
  sed -n "s/.*\"${key}\"[[:space:]]*:[[:space:]]*\([0-9][0-9]*\).*/\1/p" | head -1
}

# ─── Phase 1: Data Collection ────────────────────────────────────────────────

STAT_FIRST_TS=0
STAT_LAST_TS=0
STAT_DAYS=0
STAT_SESSIONS=0
STAT_MESSAGES=0
STAT_INPUT_TOKENS=0
STAT_OUTPUT_TOKENS=0
STAT_TOTAL_TOKENS=0
STAT_EST_COST="0.00"
STAT_AGENTS=0
STAT_SKILLS=0
STAT_CHANNELS=""
STAT_FAV_MODEL=""
STAT_PEAK_HOUR=""
STAT_PEAK_LABEL=""
declare -a STAT_HOUR_COUNTS

collect_data() {
  info "$(t scanning)"
  echo ""

  if [[ ! -d "$OPENCLAW_STATE" ]]; then
    warn "$(t no_data) $OPENCLAW_STATE"
    return 1
  fi

  validate_state_dir "$OPENCLAW_STATE"

  collect_agents
  collect_sessions
  collect_tokens_and_messages
  collect_channels
  collect_models
  collect_skills
  compute_peak_hours
  estimate_cost

  local now
  now=$(now_ts)
  if [[ "$STAT_FIRST_TS" -gt 0 ]]; then
    STAT_DAYS=$(( (now - STAT_FIRST_TS) / 86400 ))
    [[ "$STAT_DAYS" -lt 1 ]] && STAT_DAYS=1
  fi

  [[ "$STAT_LAST_TS" -eq 0 ]] && STAT_LAST_TS=$now
  return 0
}

collect_agents() {
  if [[ -d "$OPENCLAW_STATE/agents" ]]; then
    STAT_AGENTS=$(find "$OPENCLAW_STATE/agents" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
  fi
}

collect_sessions() {
  local earliest=0 latest=0

  STAT_SESSIONS=$(find "$OPENCLAW_STATE/agents" -path "*/sessions/*.jsonl*" -type f 2>/dev/null | wc -l | tr -d ' ')

  # Timestamps from sessions.json (updatedAt tracks last activity per route)
  while IFS= read -r sf; do
    if has_cmd jq; then
      local raw_earliest raw_latest
      raw_earliest=$(jq -r '[.[].updatedAt // 0] | map(select(. != 0)) | sort | first // 0' "$sf" 2>/dev/null || echo 0)
      raw_latest=$(jq -r '[.[].updatedAt // 0] | map(select(. != 0)) | sort | last // 0' "$sf" 2>/dev/null || echo 0)

      local e_s l_s
      e_s=$(to_epoch_s "$raw_earliest")
      l_s=$(to_epoch_s "$raw_latest")

      if [[ "$e_s" -gt 0 ]] && { [[ "$earliest" -eq 0 ]] || [[ "$e_s" -lt "$earliest" ]]; }; then
        earliest=$e_s
      fi
      [[ "$l_s" -gt "$latest" ]] && latest=$l_s
    fi
  done < <(find "$OPENCLAW_STATE/agents" -path "*/sessions/sessions.json" 2>/dev/null)

  STAT_FIRST_TS=$earliest
  STAT_LAST_TS=$latest

  # Also check JSONL headers for the earliest session start
  while IFS= read -r jsonl; do
    local raw_ts
    if has_cmd jq; then
      raw_ts=$(head -1 "$jsonl" | jq -r '.timestamp // 0' 2>/dev/null || echo 0)
    else
      raw_ts=$(head -1 "$jsonl" | grep_json_num "timestamp" || echo 0)
    fi
    local s
    s=$(to_epoch_s "$raw_ts")
    if [[ "$s" -gt 0 ]] && { [[ "$STAT_FIRST_TS" -eq 0 ]] || [[ "$s" -lt "$STAT_FIRST_TS" ]]; }; then
      STAT_FIRST_TS=$s
    fi
    if [[ "$s" -gt "$STAT_LAST_TS" ]]; then
      STAT_LAST_TS=$s
    fi
  done < <(find "$OPENCLAW_STATE/agents" -path "*/sessions/*.jsonl*" -type f 2>/dev/null | head -50)
}

collect_tokens_and_messages() {
  local total_input=0 total_output=0 total_all=0 msg_count=0
  local cli_tokens=false

  # Prefer CLI for token totals — sessions.json counters reset on each session reset
  if has_cmd openclaw && has_cmd jq; then
    local usage_out
    usage_out=$(openclaw status --usage --json 2>/dev/null || echo "")
    if [[ -n "$usage_out" ]]; then
      local cli_in cli_out cli_tot
      cli_in=$(echo "$usage_out" | jq -r '.inputTokens // .totalInputTokens // 0' 2>/dev/null || echo 0)
      cli_out=$(echo "$usage_out" | jq -r '.outputTokens // .totalOutputTokens // 0' 2>/dev/null || echo 0)
      cli_tot=$(echo "$usage_out" | jq -r '.totalTokens // 0' 2>/dev/null || echo 0)
      if [[ "$cli_tot" -gt 0 || "$cli_in" -gt 0 ]]; then
        total_input=$cli_in; total_output=$cli_out; total_all=$cli_tot
        cli_tokens=true
      fi
    fi
  fi

  # Fallback: sum from sessions.json (only reflects current active sessions)
  if [[ "$cli_tokens" == false ]]; then
    while IFS= read -r sf; do
      if has_cmd jq; then
        local inp out tot
        inp=$(jq '[.[].inputTokens // 0] | add // 0' "$sf" 2>/dev/null || echo 0)
        out=$(jq '[.[].outputTokens // 0] | add // 0' "$sf" 2>/dev/null || echo 0)
        tot=$(jq '[.[].totalTokens // 0] | add // 0' "$sf" 2>/dev/null || echo 0)
        total_input=$((total_input + inp))
        total_output=$((total_output + out))
        total_all=$((total_all + tot))
      fi
    done < <(find "$OPENCLAW_STATE/agents" -path "*/sessions/sessions.json" 2>/dev/null)
  fi

  while IFS= read -r jsonl; do
    local c
    c=$(grep -c '"type"[[:space:]]*:[[:space:]]*"message"' "$jsonl" 2>/dev/null || echo 0)
    msg_count=$((msg_count + c))
  done < <(find "$OPENCLAW_STATE/agents" -path "*/sessions/*.jsonl*" -type f 2>/dev/null \
    | sort -r | head -200)

  STAT_INPUT_TOKENS=$total_input
  STAT_OUTPUT_TOKENS=$total_output
  STAT_TOTAL_TOKENS=$total_all
  STAT_MESSAGES=$msg_count

  if [[ "$STAT_TOTAL_TOKENS" -eq 0 ]] && [[ "$STAT_INPUT_TOKENS" -gt 0 ]]; then
    STAT_TOTAL_TOKENS=$((STAT_INPUT_TOKENS + STAT_OUTPUT_TOKENS))
  fi
}

collect_channels() {
  local cfg="$OPENCLAW_STATE/openclaw.json"
  [[ -f "$cfg" ]] || return

  local channels_list=""
  if has_cmd jq; then
    channels_list=$(jq -r '.channels // {} | keys | join(", ")' "$cfg" 2>/dev/null || echo "")
  else
    channels_list=$(grep -oE '"(whatsapp|telegram|discord|slack|wechat|dingtalk|feishu|signal|matrix|imessage|line|teams|webex|googlechat|irc|nostr|mastodon|bluesky|twitter|email|sms)"' "$cfg" 2>/dev/null | tr -d '"' | sort -u | paste -sd ", " - 2>/dev/null || echo "")
  fi
  [[ -n "$channels_list" ]] && STAT_CHANNELS="$channels_list"
}

collect_models() {
  local found_models=""

  while IFS= read -r auth_file; do
    if has_cmd jq; then
      local providers model_ids
      providers=$(jq -r 'to_entries[] | select(.value.provider) | .value.provider' "$auth_file" 2>/dev/null || echo "")
      model_ids=$(jq -r 'to_entries[] | select(.value.modelId) | .value.modelId' "$auth_file" 2>/dev/null || echo "")
      [[ -n "$providers" ]] && found_models="${found_models}${providers}"$'\n'
      [[ -n "$model_ids" ]] && found_models="${found_models}${model_ids}"$'\n'
    fi
  done < <(find "$OPENCLAW_STATE/agents" -name "auth-profiles.json" 2>/dev/null)

  if [[ -z "$found_models" ]]; then
    local cfg="$OPENCLAW_STATE/openclaw.json"
    if [[ -f "$cfg" ]] && has_cmd jq; then
      local p
      p=$(jq -r '.providers // {} | keys | first // empty' "$cfg" 2>/dev/null || echo "")
      [[ -n "$p" ]] && found_models="$p"
    fi
  fi

  if [[ -n "$found_models" ]]; then
    STAT_FAV_MODEL=$(echo "$found_models" | grep -v '^$' | sort | uniq -c | sort -rn | head -1 | awk '{$1=""; sub(/^ +/,""); print}')
  fi
}

collect_skills() {
  if [[ -d "$OPENCLAW_STATE/skills" ]]; then
    STAT_SKILLS=$(find "$OPENCLAW_STATE/skills" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
  fi
}

compute_peak_hours() {
  STAT_HOUR_COUNTS=()
  for i in {0..23}; do STAT_HOUR_COUNTS[$i]=0; done

  while IFS= read -r jsonl; do
    while IFS= read -r raw_ts; do
      local s
      s=$(to_epoch_s "$raw_ts")
      [[ "$s" -le 0 ]] && continue
      local h
      if is_macos; then
        h=$(date -r "$s" "+%H" 2>/dev/null || echo "")
      else
        h=$(date -d "@$s" "+%H" 2>/dev/null || echo "")
      fi
      if [[ -n "$h" ]]; then
        h=$((10#$h))
        STAT_HOUR_COUNTS[$h]=$(( ${STAT_HOUR_COUNTS[$h]:-0} + 1 ))
      fi
    done < <(
      if has_cmd jq; then
        grep '"timestamp"' "$jsonl" 2>/dev/null | head -200 |
          sed -n 's/.*"timestamp"[[:space:]]*:[[:space:]]*\([^,}]*\).*/\1/p' |
          tr -d '"' | tr -d ' '
      else
        head -200 "$jsonl" 2>/dev/null |
          sed -n 's/.*"timestamp"[[:space:]]*:[[:space:]]*\([^,}]*\).*/\1/p' |
          tr -d '"' | tr -d ' '
      fi
    )
  done < <(find "$OPENCLAW_STATE/agents" -path "*/sessions/*.jsonl*" -type f 2>/dev/null | head -30)

  local max_count=0 max_hour=0
  for i in {0..23}; do
    if [[ ${STAT_HOUR_COUNTS[$i]:-0} -gt $max_count ]]; then
      max_count=${STAT_HOUR_COUNTS[$i]:-0}
      max_hour=$i
    fi
  done

  if [[ $max_count -gt 0 ]]; then
    local end_hour=$(( (max_hour + 3) % 24 ))
    STAT_PEAK_HOUR=$(printf "%02d:00 ~ %02d:00" "$max_hour" "$end_hour")

    if [[ $max_hour -ge 22 || $max_hour -le 3 ]]; then
      STAT_PEAK_LABEL=$(t night_owl)
    elif [[ $max_hour -ge 5 && $max_hour -le 8 ]]; then
      STAT_PEAK_LABEL=$(t early_bird)
    else
      STAT_PEAK_LABEL=$(t steady)
    fi
  fi
}

estimate_cost() {
  if has_cmd openclaw; then
    local cost_output
    cost_output=$(openclaw status --usage --json 2>/dev/null || echo "")
    if [[ -n "$cost_output" ]] && has_cmd jq; then
      local c
      c=$(echo "$cost_output" | jq -r '.totalCost // empty' 2>/dev/null || echo "")
      if [[ -n "$c" ]]; then
        STAT_EST_COST="$c"
        return
      fi
    fi
  fi

  # Blended rate: ~$3/M input, ~$15/M output, converted to CNY (×7)
  if [[ "$STAT_INPUT_TOKENS" -gt 0 || "$STAT_OUTPUT_TOKENS" -gt 0 ]]; then
    STAT_EST_COST=$(awk "BEGIN { printf \"%.2f\", ($STAT_INPUT_TOKENS * 3 + $STAT_OUTPUT_TOKENS * 15) / 1000000 * 7 }")
  elif [[ "$STAT_TOTAL_TOKENS" -gt 0 ]]; then
    STAT_EST_COST=$(awk "BEGIN { printf \"%.2f\", $STAT_TOTAL_TOKENS * 8 / 1000000 * 7 }")
  fi
}

# ─── Phase 2: Wrapped Renderer ───────────────────────────────────────────────

# Use a line-based layout (no right-side box border) to avoid CJK/emoji width issues
RULER="════════════════════════════════════════════════"
THIN_RULER="────────────────────────────────────────────────"

# Right-pad a label to a target display width, accounting for CJK double-width chars
print_stat() {
  local emoji="$1" label="$2" value="$3" target_w=12
  local byte_len char_len cjk_extra pad
  byte_len=$(printf '%s' "$label" | wc -c | tr -d ' ')
  char_len=${#label}
  cjk_extra=$(( (byte_len - char_len) / 2 ))
  pad=$(( target_w - char_len - cjk_extra ))
  [[ $pad -lt 0 ]] && pad=0
  printf "  %s  %s%*s  %s\n" "$emoji" "$label" "$pad" "" "$value"
}

render_sparkline() {
  local bars=("▁" "▂" "▃" "▄" "▅" "▆" "▇" "█")
  local max=0
  for i in {0..23}; do
    [[ ${STAT_HOUR_COUNTS[$i]:-0} -gt $max ]] && max=${STAT_HOUR_COUNTS[$i]:-0}
  done
  [[ $max -eq 0 ]] && max=1

  local sparkline=""
  for i in {0..23}; do
    local v=${STAT_HOUR_COUNTS[$i]:-0}
    local idx=$(( v * 7 / max ))
    sparkline="${sparkline}${bars[$idx]}"
  done
  echo "$sparkline"
}

render_wrapped() {
  echo ""

  local first_date="?"
  [[ "$STAT_FIRST_TS" -gt 0 ]] && first_date=$(format_date "$STAT_FIRST_TS")
  local today
  today=$(today_str)

  # ── Title ──
  echo "  ${BLD}${MAG}${RULER}${RST}"
  echo ""
  echo "            ${BLD}${MAG}🐾  $(t title)${RST}"
  echo ""
  echo "  ${DIM}${THIN_RULER}${RST}"
  echo ""

  # ── Stats ──
  local unit_d=" days" unit_s="" unit_m="" unit_a="" unit_sk=""
  if [[ "$OPT_LANG" != "en" ]]; then
    unit_d=" 天" unit_s=" 次" unit_m=" 条" unit_a=" 个" unit_sk=" 个"
  fi

  local tokens_fmt
  tokens_fmt=$(format_number "$STAT_TOTAL_TOKENS")

  print_stat "${CYN}📅${RST}" "$(t days)" "${BLD}${STAT_DAYS}${unit_d}${RST}（${first_date} ~ ${today}）"
  print_stat "${CYN}💬${RST}" "$(t sessions)" "${BLD}${STAT_SESSIONS}${unit_s}${RST}"
  print_stat "${CYN}📨${RST}" "$(t messages)" "${BLD}${STAT_MESSAGES}${unit_m}${RST}"
  print_stat "${CYN}🧠${RST}" "$(t tokens)" "${BLD}${tokens_fmt} tokens${RST}"
  print_stat "${CYN}💰${RST}" "$(t cost)" "${BLD}≈ ¥${STAT_EST_COST}${RST}"
  print_stat "${CYN}🤖${RST}" "$(t agents)" "${BLD}${STAT_AGENTS}${unit_a}${RST}"
  print_stat "${CYN}🔧${RST}" "$(t skills)" "${BLD}${STAT_SKILLS}${unit_sk}${RST}"

  [[ -n "$STAT_CHANNELS" ]] &&
    print_stat "${CYN}📱${RST}" "$(t channels)" "${BLD}${STAT_CHANNELS}${RST}"

  [[ -n "$STAT_PEAK_HOUR" ]] &&
    print_stat "${CYN}🌙${RST}" "$(t peak_hour)" "${BLD}${STAT_PEAK_HOUR}${RST}（${STAT_PEAK_LABEL}）"

  [[ -n "$STAT_FAV_MODEL" ]] &&
    print_stat "${CYN}🏆${RST}" "$(t fav_model)" "${BLD}${STAT_FAV_MODEL}${RST}"

  # ── Sparkline ──
  local has_activity=false
  for i in {0..23}; do
    [[ ${STAT_HOUR_COUNTS[$i]:-0} -gt 0 ]] && { has_activity=true; break; }
  done

  if [[ "$has_activity" == true ]]; then
    echo ""
    echo "  ${GRY}── $(t activity) ──${RST}"
    echo "  ${GRY}$(render_sparkline)${RST}"
    echo "  ${DIM}0     6     12    18  23${RST}"
  fi

  # ── Farewell ──
  echo ""
  echo "  ${DIM}${THIN_RULER}${RST}"
  echo ""

  local quote
  if [[ "$OPT_LANG" == "en" ]]; then
    quote="  \"Your ${STAT_SESSIONS} $(t farewell_quote).\""
  else
    quote="  \"你与 AI 的 ${STAT_SESSIONS} 次会话。\""
  fi
  echo "  ${YLW}${BLD}${quote}${RST}"
  echo "  ${YLW}$(t farewell_power)${RST}"
  echo ""
  echo "  ${DIM}$(t disclaimer)${RST}"

  echo ""
  echo "  ${BLD}${MAG}${RULER}${RST}"
  echo ""

  generate_share_text
}

generate_share_text() {
  local first_date="?"
  [[ "$STAT_FIRST_TS" -gt 0 ]] && first_date=$(format_date "$STAT_FIRST_TS")
  local today tokens_fmt
  today=$(today_str)
  tokens_fmt=$(format_number "$STAT_TOTAL_TOKENS")

  local share_text
  if [[ "$OPT_LANG" == "en" ]]; then
    share_text="$(cat <<EOF
🐾 My OpenClaw Journey · Wrapped

📅 ${STAT_DAYS} days together (${first_date} ~ ${today})
💬 ${STAT_SESSIONS} conversations | 📨 ${STAT_MESSAGES} messages
🧠 ${tokens_fmt} tokens | 💰 ≈ ¥${STAT_EST_COST}
🤖 ${STAT_AGENTS} agents | 🔧 ${STAT_SKILLS} skills
EOF
)"
    [[ -n "$STAT_PEAK_HOUR" ]] && share_text="${share_text}"$'\n'"🌙 Peak: ${STAT_PEAK_HOUR} (${STAT_PEAK_LABEL})"
    [[ -n "$STAT_FAV_MODEL" ]] && share_text="${share_text}"$'\n'"🏆 Favorite: ${STAT_FAV_MODEL}"
    share_text="${share_text}"$'\n\n'"Farewell, OpenClaw! #ClawfatherWrapped #OpenClaw"
  else
    share_text="$(cat <<EOF
🐾 我的 OpenClaw 之旅 · Wrapped

📅 相伴 ${STAT_DAYS} 天（${first_date} ~ ${today}）
💬 ${STAT_SESSIONS} 次对话 | 📨 ${STAT_MESSAGES} 条消息
🧠 ${tokens_fmt} tokens | 💰 ≈ ¥${STAT_EST_COST}
🤖 ${STAT_AGENTS} 个智能体 | 🔧 ${STAT_SKILLS} 个 Skills
EOF
)"
    [[ -n "$STAT_PEAK_HOUR" ]] && share_text="${share_text}"$'\n'"🌙 最活跃: ${STAT_PEAK_HOUR}（${STAT_PEAK_LABEL}）"
    [[ -n "$STAT_FAV_MODEL" ]] && share_text="${share_text}"$'\n'"🏆 最爱: ${STAT_FAV_MODEL}"
    share_text="${share_text}"$'\n\n'"后会有期，OpenClaw！#ClawfatherWrapped #OpenClaw"
  fi

  local desktop_path
  if is_macos; then
    desktop_path="$HOME/Desktop"
  else
    desktop_path="${XDG_DESKTOP_DIR:-$HOME/Desktop}"
  fi

  if [[ "$OPT_DRY_RUN" == true ]]; then return; fi

  if [[ -d "$desktop_path" ]]; then
    local report_file="${desktop_path}/openclaw-wrapped.txt"
    if [[ -f "$report_file" ]]; then
      local ts
      ts=$(date "+%Y%m%d%H%M%S")
      report_file="${desktop_path}/openclaw-wrapped-${ts}.txt"
    fi
    printf '%s\n' "$share_text" > "$report_file"
    ok "📄 ${report_file}"
  fi
}

# ─── Phase 3: Uninstall Engine ────────────────────────────────────────────────

ITEMS_TO_REMOVE=()

survey_removals() {
  ITEMS_TO_REMOVE=()

  if has_cmd openclaw; then
    ITEMS_TO_REMOVE+=("cli:openclaw CLI ($(command -v openclaw))")
  fi

  if [[ -d "$OPENCLAW_STATE" ]] && [[ "$OPT_KEEP_CONFIG" == false ]]; then
    ITEMS_TO_REMOVE+=("state:${OPENCLAW_STATE}")
  elif [[ -d "$OPENCLAW_STATE" ]] && [[ "$OPT_KEEP_CONFIG" == true ]]; then
    ITEMS_TO_REMOVE+=("state_partial:${OPENCLAW_STATE}/agents (sessions only)")
  fi

  if [[ -d "$OPENCLAW_STATE/workspace" ]] && [[ "$OPT_KEEP_CONFIG" == false ]]; then
    ITEMS_TO_REMOVE+=("workspace:$OPENCLAW_STATE/workspace")
  fi

  if is_macos; then
    [[ -f "$HOME/Library/LaunchAgents/bot.molt.gateway.plist" ]] &&
      ITEMS_TO_REMOVE+=("launchd:bot.molt.gateway (launchd service)")
    for plist in "$HOME/Library/LaunchAgents"/com.openclaw.*.plist; do
      [[ -f "$plist" ]] && ITEMS_TO_REMOVE+=("launchd:$plist")
    done
    [[ -d "/Applications/OpenClaw.app" ]] &&
      ITEMS_TO_REMOVE+=("app:/Applications/OpenClaw.app")
  fi

  if is_linux; then
    [[ -f "$HOME/.config/systemd/user/openclaw-gateway.service" ]] &&
      ITEMS_TO_REMOVE+=("systemd:openclaw-gateway.service")
  fi

  while IFS= read -r p; do
    [[ -n "$p" ]] || continue
    local resolved_p
    resolved_p=$(cd "$p" 2>/dev/null && pwd -P) || resolved_p="$p"
    local base_p
    base_p=$(basename "$resolved_p")
    if [[ "$base_p" != .openclaw* ]]; then continue; fi
    if [[ "$resolved_p" == "$HOME" ]]; then continue; fi
    ITEMS_TO_REMOVE+=("profile:$p")
  done < <(find "$HOME" -maxdepth 1 -name ".openclaw-*" -type d 2>/dev/null || true)
}

print_removal_list() {
  echo ""
  echo "${BLD}$(t will_remove)${RST}"
  echo ""
  for item in "${ITEMS_TO_REMOVE[@]}"; do
    local kind="${item%%:*}" desc="${item#*:}"
    case "$kind" in
      cli)           echo "  ${RED}●${RST} CLI: $desc" ;;
      state)         echo "  ${RED}●${RST} State: $desc" ;;
      state_partial) echo "  ${YLW}●${RST} Sessions: $desc" ;;
      workspace)     echo "  ${RED}●${RST} Workspace: $desc" ;;
      launchd)       echo "  ${RED}●${RST} Service: $desc" ;;
      systemd)       echo "  ${RED}●${RST} Service: $desc" ;;
      app)           echo "  ${RED}●${RST} App: $desc" ;;
      profile)       echo "  ${RED}●${RST} Profile: $desc" ;;
    esac
  done

  if [[ "$OPT_KEEP_CONFIG" == true ]]; then
    echo ""
    echo "  ${GRN}●${RST} Config $(t kept)"
  fi
  echo ""
}

do_uninstall() {
  local total=${#ITEMS_TO_REMOVE[@]} current=0

  for item in "${ITEMS_TO_REMOVE[@]}"; do
    current=$((current + 1))
    local kind="${item%%:*}" desc="${item#*:}"
    echo "  [${current}/${total}] ${kind}..."

    case "$kind" in
      cli)           uninstall_cli ;;
      state)         rm -rf "$OPENCLAW_STATE" && ok "Removed ${OPENCLAW_STATE}" ;;
      state_partial)
        find "$OPENCLAW_STATE/agents" -name "*.jsonl" -delete 2>/dev/null || true
        find "$OPENCLAW_STATE/agents" -name "sessions.json" -delete 2>/dev/null || true
        ok "Cleaned session data"
        ;;
      workspace)     rm -rf "$OPENCLAW_STATE/workspace" && ok "Removed workspace" ;;
      launchd)       uninstall_launchd "$desc" ;;
      systemd)       uninstall_systemd ;;
      app)           rm -rf "/Applications/OpenClaw.app" && ok "Removed OpenClaw.app" ;;
      profile)       rm -rf "$desc" && ok "Removed $desc" ;;
    esac
  done
}

uninstall_cli() {
  if has_cmd openclaw; then
    info "Running official uninstall..."
    openclaw gateway stop  >/dev/null 2>&1 || true
    ok "Gateway stopped"
    openclaw gateway uninstall >/dev/null 2>&1 || true
    ok "Gateway service removed"
  fi

  has_cmd npm  && { npm rm -g openclaw  >/dev/null 2>&1 || true; }
  has_cmd pnpm && { pnpm remove -g openclaw >/dev/null 2>&1 || true; }
  has_cmd bun  && { bun remove -g openclaw  >/dev/null 2>&1 || true; }

  hash -r 2>/dev/null || true
  ok "CLI uninstalled"
}

uninstall_launchd() {
  local desc="$1"
  local uid="${UID:-$(id -u)}"

  if [[ "$desc" == *"bot.molt"* ]]; then
    launchctl bootout "gui/$uid/bot.molt.gateway" 2>/dev/null || true
    rm -f "$HOME/Library/LaunchAgents/bot.molt.gateway.plist"
  fi

  for plist in "$HOME/Library/LaunchAgents"/com.openclaw.*.plist; do
    [[ -f "$plist" ]] || continue
    local label
    label=$(basename "$plist" .plist)
    launchctl bootout "gui/$uid/$label" 2>/dev/null || true
    rm -f "$plist"
  done

  ok "launchd services cleaned"
}

uninstall_systemd() {
  systemctl --user disable --now openclaw-gateway.service 2>/dev/null || true
  rm -f "$HOME/.config/systemd/user/openclaw-gateway.service"
  systemctl --user daemon-reload 2>/dev/null || true
  ok "systemd service cleaned"
}

verify_uninstall() {
  echo ""
  hash -r 2>/dev/null || true

  # openclaw CLI 或 npm rm 可能重新创建空状态目录，二次清理
  if [[ -d "$OPENCLAW_STATE" ]] && [[ "$OPT_KEEP_CONFIG" == false ]]; then
    rm -rf "$OPENCLAW_STATE"
  fi

  local clean=true

  has_cmd openclaw && { warn "openclaw still on PATH: $(command -v openclaw)"; clean=false; }
  [[ -d "$OPENCLAW_STATE" ]] && [[ "$OPT_KEEP_CONFIG" == false ]] && { warn "${OPENCLAW_STATE} still exists"; clean=false; }

  if [[ "$clean" == true ]]; then
    echo ""
    echo "  ${BLD}${GRN}╭──────────────────────────────────────────╮${RST}"
    echo "  ${BLD}${GRN}│                                          │${RST}"
    echo "  ${BLD}${GRN}│    🐾  $(t uninstall_done)${RST}"
    echo "  ${BLD}${GRN}│                                          │${RST}"
    echo "  ${BLD}${GRN}╰──────────────────────────────────────────╯${RST}"
    echo ""
  fi
}

# ─── Main ─────────────────────────────────────────────────────────────────────

main() {
  parse_args "$@"
  setup_colors

  echo ""
  echo "  ${BLD}${MAG}🐾 Clawfather Uninstaller v${VERSION}${RST}"
  echo "  ${GRY}${THIN_RULER}${RST}"
  echo ""

  local has_data=true
  collect_data || has_data=false

  [[ "$has_data" == true ]] && render_wrapped

  if [[ "$OPT_WRAPPED_ONLY" == true ]]; then
    exit 0
  fi

  survey_removals

  if [[ ${#ITEMS_TO_REMOVE[@]} -eq 0 ]]; then
    ok "No OpenClaw components found to clean up."
    exit 0
  fi

  print_removal_list

  if [[ "$OPT_DRY_RUN" == true ]]; then
    info "$(t skip_dry)"
    exit 0
  fi

  if ! confirm "$(t confirm_uninstall)"; then
    info "Cancelled."
    exit 0
  fi

  echo ""
  do_uninstall
  verify_uninstall
}

main "$@"
