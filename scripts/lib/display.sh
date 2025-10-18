#!/usr/bin/env bash
set -Eeuo pipefail

PROGRAM_NAME="display"
VERSION="4.0.0"
AUTHOR="Terminal Display CLI"

# 默认配置
DEFAULT_WIDTH=72
DEFAULT_BORDER="double"
DEFAULT_COLOR="WHITE"
TITLE_COLOR="YELLOW"
BORDER_COLOR="NONE"
QUIET=false
NO_COLOR=false
COLOR_OVERRIDE=false
FORCE_COLOR=false

# 颜色定义
declare -A COLORS=(
     [BLACK]=$'\033[0;30m'
     [RED]=$'\033[0;31m'
     [GREEN]=$'\033[0;32m'
     [YELLOW]=$'\033[1;33m'
     [BLUE]=$'\033[0;34m'
     [MAGENTA]=$'\033[0;35m'
     [CYAN]=$'\033[0;36m'
     [WHITE]=$'\033[1;37m'
     [GRAY]=$'\033[0;90m'
     [RESET]=$'\033[0m'
     [NONE]=""
)

# 样式定义
declare -A STYLES=(
     [BOLD]=$'\033[1m'
     [RESET]=$'\033[0m'
)

# 边框字符集 (使用安全字符, 避免 emoji)
declare -A BORDER_CHARS=(
     [ascii_tl]="+" [ascii_tr]="+" [ascii_bl]="+" [ascii_br]="+" [ascii_h]="-" [ascii_v]="|"
     [single_tl]="┌" [single_tr]="┐" [single_bl]="└" [single_br]="┘" [single_h]="─" [single_v]="│"
     [double_tl]="╔" [double_tr]="╗" [double_bl]="╚" [double_br]="╝" [double_h]="═" [double_v]="║"
     [none_tl]=" " [none_tr]=" " [none_bl]=" " [none_br]=" " [none_h]=" " [none_v]=" "
)

VALID_BORDERS="ascii single double none"
VALID_COLORS="BLACK RED GREEN YELLOW BLUE MAGENTA CYAN WHITE GRAY RESET NONE"

# 支持颜色判断：允许强制启用
supports_color() {
    if [[ ${FORCE_COLOR} == "true" ]]; then return 0; fi
    if [[ ${NO_COLOR} == "true" ]]; then return 1; fi
    return 0  # Force enable color in this environment
}
color() {
    local name="$1"
    supports_color && echo -n "${COLORS[$name]:-}" || echo -n ""
}
style() {
    local name="$1"
    supports_color && echo -n "${STYLES[$name]:-}" || echo -n ""
}

strip_ansi() {
    sed -E 's/\x1B\[[0-9;]*[mK]//g'
}

display_len() {
    local text="$1" cleaned total ascii nonascii
    cleaned=$(printf "%s" "$text" | strip_ansi)
    # 纯 Bash 估算宽度：非 ASCII 视为宽度 2, ASCII 视为 1
    total=$(printf "%s" "$cleaned" | wc -m 2> /dev/null | tr -d ' ')
    [[ -z $total ]] && total=${#cleaned}
    ascii=$(printf "%s" "$cleaned" | LC_ALL=C tr -cd '\000-\177' | wc -m 2> /dev/null | tr -d ' ')
    [[ -z $ascii ]] && ascii=${#cleaned}
    nonascii=$((total - ascii))
    echo $((ascii + nonascii * 2))
}

repeat() {
    local char="$1" count="${2:-0}"
    if [[ $count =~ ^[0-9]+$ ]] && ((count > 0)); then
        printf -v _pad '%*s' "$count" ""
        echo -n "${_pad// /$char}"
    else
        echo -n ""
    fi
}
border_char() {
    local set="$1" pos="$2"
    local key="${set}_${pos}"
    echo -n "${BORDER_CHARS[$key]:-+}"
}

usage() {
    cat << EOF
${PROGRAM_NAME} ${VERSION} - 终端格式化输出 CLI

用法:
  ${PROGRAM_NAME} [全局选项] <子命令> [参数]

子命令:
  success <消息...>       显示成功消息 (支持多行与 \n 转义)
  error <消息...>         显示错误消息 (支持多行与 \n 转义)
  warning <消息...>       显示警告消息 (支持多行与 \n 转义)
  info <消息...>          显示信息消息 (支持多行与 \n 转义)
  box <标题> <内容...>    显示盒子 (支持多行与 \n 转义, 或管道)
  banner <标题> [行...]    显示居中横幅
  section <标题> [行...]   显示章节
  progress <当前> <总数> [文本]  显示进度条

全局选项:
  -w, --width <N>          设置宽度 (>=20, 默认 ${DEFAULT_WIDTH})
  -b, --border <样式>      边框样式: ${VALID_BORDERS} (默认 ${DEFAULT_BORDER})
  -c, --color <颜色>       文本颜色: ${VALID_COLORS} (默认 ${DEFAULT_COLOR})
  --title-color <颜色>     标题颜色 (独立于 --color, 默认 ${TITLE_COLOR})
  --border-color <颜色>    边框颜色 (默认 ${BORDER_COLOR})
  --color-mode <m>         颜色模式: auto|always|never
  --force-color            强制启用颜色 (等价于 --color-mode always)
  --no-color               禁用颜色 (等价于 --color-mode never)
  -q, --quiet              静默模式
  -h, --help               显示帮助
  -V, --version            显示版本

作者: ${AUTHOR}
EOF
}

version() {
    echo "${PROGRAM_NAME} ${VERSION}"
}

err() {
    echo "错误: $*" >&2
    exit 1
}
warn() {
    echo "警告: $*" >&2
}

render_box() {
    local title="$1" content="$2" width="${3:-$DEFAULT_WIDTH}" border="${4:-$DEFAULT_BORDER}" color_name="${5:-$DEFAULT_COLOR}"
    ((width >= 20)) || err "宽度必须至少为20"
    local tl tr bl br h v
    tl=$(border_char "$border" "tl")
    tr=$(border_char "$border" "tr")
    bl=$(border_char "$border" "bl")
    br=$(border_char "$border" "br")
    h=$(border_char "$border" "h")
    v=$(border_char "$border" "v")
    local bc ts tc reset
    bc=$(color "$BORDER_COLOR")
    ts="$(color "$TITLE_COLOR")$(style BOLD)"
    tc=$(color "$color_name")
    reset=$(color RESET)

    printf "%s%s%s%s%s\n" "$bc" "$tl" "$(repeat "$h" $((width - 2)))" "$tr" "$reset"

    if [[ -n $title ]]; then
        local tlen padL padR
        tlen=$(display_len "$title")
        padL=$(((width - 2 - tlen) / 2))
        padR=$((width - 2 - tlen - padL))
        printf "%s%s%s%s%s%s%s%s%s%s\n" \
            "$bc" "$v" \
            "$(repeat " " "$padL")" \
            "$ts" "$title" "$reset" \
            "$(repeat " " "$padR")" \
            "$bc" "$v" "$reset"
        [[ -n $content ]] && printf "%s%s%s%s%s\n" "$bc" "$v" "$(repeat "$h" $((width - 2)))" "$v" "$reset"
    fi

    if [[ -n $content ]]; then
        while IFS= read -r line; do
            local llen pad
            llen=$(display_len "$line")
            pad=$((width - 2 - 1 - llen))
            ((pad < 0)) && pad=0
            printf "%s%s %s%s%s%s%s%s%s\n" \
                "$bc" "$v" \
                "$tc" "$line" "$reset" \
                "$(repeat " " "$pad")" \
                "$bc" "$v" "$reset"
        done <<< "$content"
    fi

    printf "%s%s%s%s%s\n" "$bc" "$bl" "$(repeat "$h" $((width - 2)))" "$br" "$reset"
}

render_banner() {
    local title="$1"
    shift
    local lines=("$@")
    local width="${DEFAULT_WIDTH}"
    local border="${DEFAULT_BORDER}"
    local tl tr bl br h v
    tl=$(border_char "$border" tl)
    tr=$(border_char "$border" tr)
    bl=$(border_char "$border" bl)
    br=$(border_char "$border" br)
    h=$(border_char "$border" h)
    v=$(border_char "$border" v)
    local bc tc cc reset
    bc=$(color "$BORDER_COLOR")
    tc="$(color "$TITLE_COLOR")$(style BOLD)"
    cc=$(color "$DEFAULT_COLOR")
    reset=$(color RESET)

    printf "%s%s%s%s%s\n" "$bc" "$tl" "$(repeat "$h" $((width - 2)))" "$tr" "$reset"
    printf "%s%s%s%s%s\n" "$bc" "$v" "$(repeat " " $((width - 2)))" "$v" "$reset"

    if [[ -n $title ]]; then
        local tlen padL padR
        tlen=$(display_len "$title")
        padL=$(((width - 2 - tlen) / 2))
        padR=$((width - 2 - tlen - padL))
        printf "%s%s%s%s%s%s%s%s%s%s\n" "$bc" "$v" "$(repeat " " "$padL")" "$tc" "$title" "$reset" "$(repeat " " "$padR")" "$bc" "$v" "$reset"
    fi

    printf "%s%s%s%s%s\n" "$bc" "$v" "$(repeat " " $((width - 2)))" "$v" "$reset"

    local nonempty=0
    for line in "${lines[@]}"; do
        [[ -z $line ]] && continue
        local llen padL padR
        llen=$(display_len "$line")
        padL=$(((width - 2 - llen) / 2))
        padR=$((width - 2 - llen - padL))
        printf "%s%s%s%s%s%s%s%s%s%s\n" "$bc" "$v" "$(repeat " " "$padL")" "$cc" "$line" "$reset" "$(repeat " " "$padR")" "$bc" "$v" "$reset"
        nonempty=$((nonempty + 1))
    done

    (( nonempty > 0 )) && printf "%s%s%s%s%s\n" "$bc" "$v" "$(repeat " " $((width - 2)))" "$v" "$reset"
    printf "%s%s%s%s%s\n" "$bc" "$bl" "$(repeat "$h" $((width - 2)))" "$br" "$reset"
}

render_section() {
    local title="$1"
    shift
    local lines=("$@")
    local width="${DEFAULT_WIDTH}"
    printf "%s%s%s\n" "$(color "$TITLE_COLOR")$(style BOLD)" "$title" "$(color RESET)"
    printf "%s\n" "$(repeat "─" $((width / 2)))"
    for line in "${lines[@]}"; do printf "  %s%s%s\n" "$(color "$DEFAULT_COLOR")" "$line" "$(color RESET)"; done
}

render_progress() {
    local current="$1" total="$2" text="${3:-进度}" width="${4:-50}"
    [[ $current =~ ^[0-9]+$ ]] || err "当前值必须是数字"
    [[ $total =~ ^[0-9]+$ ]] || err "总值必须是数字"
    ((total > 0)) || err "总值必须大于0"
    ((current <= total)) || err "当前值不能大于总值"

    local percent=$((current * 100 / total))
    local prefix="${text}: "
    local suffix
    suffix=$(printf '%d%% (%d/%d)' "$percent" "$current" "$total")

    local prefix_len suffix_len bracket_len space_len bar_width
    prefix_len=$(display_len "$prefix")
    suffix_len=$(display_len "$suffix")
    bracket_len=2   # []
    space_len=1     # space between ] and suffix
    bar_width=$((width - prefix_len - bracket_len - space_len - suffix_len))
    ((bar_width < 0)) && bar_width=0

    local filled empty
    if ((bar_width > 0)); then
        filled=$((current * bar_width / total))
        ((filled < 0)) && filled=0
        ((filled > bar_width)) && filled=$bar_width
        empty=$((bar_width - filled))
    else
        filled=0; empty=0
    fi

    local fg bg reset
    fg=$(color GREEN)
    bg=$(color GRAY)
    reset=$(color RESET)

    printf "%s[%s%s%s] %s\n" \
        "$prefix" \
        "${fg}$(repeat "#" "$filled")" \
        "${bg}$(repeat "-" "$empty")" \
        "$reset" \
        "$suffix"
}

read_stdin_if_empty() {
    local val="$1"
    if [[ -z $val ]] && [[ ! -t 0 ]]; then cat; else echo -n "$val"; fi
}

# 新增：扩展转义序列 (安全处理 %)
expand_escapes() {
    local s="$1"
    s=${s//%/%%}
    printf '%b' "$s"
}

# 新增：收集内容, 支持从管道读取并合并参数为多行
collect_content() {
    local pieces=("$@")
    local out=""
    if [[ ! -t 0 ]]; then
        local stdin_data
        stdin_data="$(cat)"
        out="$stdin_data"
    fi
    if (( ${#pieces[@]} > 0 )); then
        local x expanded
        for x in "${pieces[@]}"; do
            expanded="$(expand_escapes "$x")"
            if [[ -z "$out" ]]; then
                out="$expanded"
            else
                out+=$'\n'"$expanded"
            fi
        done
    fi
    printf '%s' "$out"
}

# 全局用于参数解析后的剩余参数数组
PARSED_REST=()

parse_global_opts() {
    local args=("$@")
    local i=0
    while ((i < ${#args[@]})); do
        case "${args[$i]}" in
            -w | --width)
                ((i + 1 < ${#args[@]})) || err "选项 ${args[$i]} 需要参数"
                [[ ${args[$((i + 1))]} =~ ^[0-9]+$ ]] || err "宽度必须是数字"
                ((args[$((i + 1))] >= 20)) || err "宽度必须至少为20"
                DEFAULT_WIDTH="${args[$((i + 1))]}"
                i=$((i + 2))
                ;;
            -b | --border)
                case "${args[$((i + 1))]}" in ascii | single | double | none) DEFAULT_BORDER="${args[$((i + 1))]}" ;; *) err "无效边框样式" ;; esac
                i=$((i + 2))
                ;;
            -c | --color)
                ((i + 1 < ${#args[@]})) || err "选项 ${args[$i]} 需要参数"
                DEFAULT_COLOR="${args[$((i + 1))]}"
                COLOR_OVERRIDE=true
                i=$((i + 2))
                ;;
            --title-color)
                ((i + 1 < ${#args[@]})) || err "选项 ${args[$i]} 需要参数"
                TITLE_COLOR="${args[$((i + 1))]}"
                i=$((i + 2))
                ;;
            --border-color)
                ((i + 1 < ${#args[@]})) || err "选项 ${args[$i]} 需要参数"
                BORDER_COLOR="${args[$((i + 1))]}"
                i=$((i + 2))
                ;;
            --color-mode)
                ((i + 1 < ${#args[@]})) || err "选项 ${args[$i]} 需要参数"
                case "${args[$((i + 1))]}" in
                    always)
                        FORCE_COLOR=true
                        NO_COLOR=false
                        ;;
                    never)
                        FORCE_COLOR=false
                        NO_COLOR=true
                        ;;
                    auto) FORCE_COLOR=false ;;
                    *) err "无效颜色模式: ${args[$((i + 1))]}" ;;
                esac
                i=$((i + 2))
                ;;
            --force-color)
                FORCE_COLOR=true
                NO_COLOR=false
                i=$((i + 1))
                ;;
            --no-color)
                NO_COLOR=true
                FORCE_COLOR=false
                i=$((i + 1))
                ;;
            -q | --quiet)
                QUIET=true
                i=$((i + 1))
                ;;
            --)
                i=$((i + 1))
                break
                ;;
            -h | --help | -V | --version)
                break
                ;;
            *) break ;;
        esac
    done
    PARSED_REST=("${args[@]:i}")
}

main() {
    # 从环境变量继承 FORCE_COLOR
    if [[ ${FORCE_COLOR:-} == "1" ]]; then FORCE_COLOR=true; fi
    if [[ ${FORCE_COLOR:-} == "true" ]]; then FORCE_COLOR=true; fi
    # 未强制时根据 TTY/TERM 自动禁用
    if [[ $FORCE_COLOR != "true" ]]; then
        [[ ! -t 1 || ${TERM:-} == "dumb" ]] && NO_COLOR=true
    fi

    local raw=("$@")
    for x in "${raw[@]}"; do
        case "$x" in
            -V | --version)
                version
                return 0
                ;;
            -h | --help)
                usage
                return 0
                ;;
        esac
    done

    parse_global_opts "${raw[@]}"
    local rest
    rest=("${PARSED_REST[@]}")
    local sub="${rest[0]:-}"
    [[ -z $sub ]] && {
        usage
        exit 1
    }
    set -- "${rest[@]:1}"

    case "$sub" in
        success)
            local content
            content="$(collect_content "$@")"
            [[ -n $content ]] || err "success 需要消息参数或管道输入"
            if [ "$QUIET" != "true" ]; then
                local eff_color="$DEFAULT_COLOR"
                [ "$COLOR_OVERRIDE" != "true" ] && eff_color="GREEN"
                render_box "SUCCESS" "$content" "$DEFAULT_WIDTH" "$DEFAULT_BORDER" "$eff_color"
            fi
            ;;
        error)
            local content
            content="$(collect_content "$@")"
            [[ -n $content ]] || err "error 需要消息参数或管道输入"
            if [ "$QUIET" != "true" ]; then
                local eff_color="$DEFAULT_COLOR"
                [ "$COLOR_OVERRIDE" != "true" ] && eff_color="RED"
                render_box "ERROR" "$content" "$DEFAULT_WIDTH" "$DEFAULT_BORDER" "$eff_color"
            fi
            ;;
        warning)
            local content
            content="$(collect_content "$@")"
            [[ -n $content ]] || err "warning 需要消息参数或管道输入"
            if [ "$QUIET" != "true" ]; then
                local eff_color="$DEFAULT_COLOR"
                [ "$COLOR_OVERRIDE" != "true" ] && eff_color="YELLOW"
                render_box "WARNING" "$content" "$DEFAULT_WIDTH" "$DEFAULT_BORDER" "$eff_color"
            fi
            ;;
        info)
            local content
            content="$(collect_content "$@")"
            [[ -n $content ]] || err "info 需要消息参数或管道输入"
            if [ "$QUIET" != "true" ]; then
                local eff_color="$DEFAULT_COLOR"
                [ "$COLOR_OVERRIDE" != "true" ] && eff_color="CYAN"
                render_box "INFO" "$content" "$DEFAULT_WIDTH" "$DEFAULT_BORDER" "$eff_color"
            fi
            ;;
        box)
            local title="${1:-}"
            [[ -n $title ]] || err "box 需要标题"
            shift || true
            local content
            content="$(collect_content "$@")"
            [ "$QUIET" != "true" ] && render_box "$title" "$content" "$DEFAULT_WIDTH" "$DEFAULT_BORDER" "$DEFAULT_COLOR"
            ;;
        banner)
            if [[ ! -t 0 && $# -eq 0 ]]; then
                local line
                line=$(cat)
                [ "$QUIET" != "true" ] && render_banner "$line"
            else
                [[ $# -ge 1 ]] || err "banner 需要至少一个参数"
                local title="$1"
                shift
                [ "$QUIET" != "true" ] && render_banner "$title" "$@"
            fi
            ;;
        section)
            if [[ ! -t 0 && $# -eq 1 ]]; then render_section "$1" "$(cat)"; else
                [[ $# -ge 1 ]] || err "section 需要至少一个参数"
                local title="$1"
                shift
                render_section "$title" "$@"
            fi
            ;;
        progress)
            [[ $# -ge 2 ]] || err "progress 需要至少两个参数 (当前 总数)"
            local current="$1" total="$2" text="${3:-进度}"
            render_progress "$current" "$total" "$text" "$DEFAULT_WIDTH"
            ;;
        *)
            err "未知的子命令: $sub"
            ;;
    esac
}

main "$@"
