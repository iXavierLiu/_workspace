#!/bin/bash
# disk_alert.sh - 简化版硬盘健康监控脚本
# 功能：检测硬盘健康状态，输出详细信息和设备总览
# 版本：2.0 - 简化版

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 全局变量
SCRIPT_VERSION="2.0"
DEVICE_SUMMARY=()  # 存储设备状态摘要

# 检查smartctl命令是否存在
# 功能：验证系统是否安装了smartmontools工具
# 返回：0-存在，1-不存在
check_smartctl() {
    if ! command -v smartctl >/dev/null 2>&1; then
        echo -e "${RED}❌ 错误：未找到smartctl命令${NC}"
        echo -e "${YELLOW}请安装smartmontools工具包：${NC}"
        echo -e "${BLUE}Ubuntu/Debian: sudo apt-get install smartmontools${NC}"
        echo -e "${BLUE}CentOS/RHEL: sudo dnf install smartmontools${NC}"
        return 1
    fi
    return 0
}

# 获取SMART数据
# 功能：安全地获取指定硬盘的SMART数据，正确处理smartctl退出码
# 参数：$1 - 硬盘设备路径
# 返回：SMART数据或空字符串
# 说明：smartctl使用位掩码退出码，64(bit 6)表示错误日志有记录但不影响数据获取
get_smart_data() {
    local disk="$1"
    
    # 检查设备是否存在
    if [[ ! -e "$disk" ]]; then
        return 1
    fi
    
    # 获取SMART数据
    local smart_output
    smart_output=$(smartctl -a "$disk" 2>/dev/null)
    local exit_code=$?
    
    # 检查致命错误（bit 0-2: 命令解析失败、设备打开失败、SMART命令失败）
    # 这些错误会阻止我们获取有效数据
    if (( exit_code & 7 )); then
        return 1
    fi
    
    # 如果有输出数据，即使有警告级别的退出码也返回数据
    # bit 3-7 表示各种警告和错误记录，但不影响数据获取
    if [[ -n "$smart_output" ]]; then
        echo "$smart_output"
        return 0
    fi
    
    return 1
}

# 提取SMART属性值
# 功能：从SMART输出中提取指定属性的数值
# 参数：$1 - SMART数据，$2 - 属性名称，$3 - 字段位置（默认10）
# 返回：属性值或0
get_smart_value() {
    local smart_data="$1"
    local attribute="$2"
    local field="${3:-10}"
    
    local value=$(echo "$smart_data" | grep "$attribute" | awk "{print \$$field}" | head -n1)
    echo "${value:-0}"
}

# 计算简化健康评分
# 功能：基于关键指标计算硬盘健康评分
# 参数：$1 - 重映射扇区，$2 - 待处理扇区，$3 - 温度
# 返回：健康评分（0-100）
calculate_health_score() {
    local realloc="$1"
    local pending="$2"
    local temp="$3"
    
    local score=100
    
    # 重映射扇区影响评分
    if [[ "$realloc" -gt 50 ]]; then
        score=$((score - 40))
    elif [[ "$realloc" -gt 10 ]]; then
        score=$((score - 20))
    elif [[ "$realloc" -gt 0 ]]; then
        score=$((score - 10))
    fi
    
    # 待处理扇区影响评分
    if [[ "$pending" -gt 0 ]]; then
        score=$((score - 30))
    fi
    
    # 温度影响评分
    if [[ "$temp" -gt 70 ]]; then
        score=$((score - 20))
    elif [[ "$temp" -gt 60 ]]; then
        score=$((score - 10))
    fi
    
    # 确保评分不低于0
    [[ "$score" -lt 0 ]] && score=0
    
    echo "$score"
}

# 格式化时间显示
# 功能：将小时数转换为易读格式
# 参数：$1 - 小时数
# 返回：格式化的时间字符串
format_hours() {
    local hours="$1"
    
    if [[ "$hours" -eq 0 ]]; then
        echo "0小时"
        return
    fi
    
    local days=$((hours / 24))
    local years=$((days / 365))
    local remaining_days=$((days % 365))
    local remaining_hours=$((hours % 24))
    
    local result=""
    
    if [[ "$years" -gt 0 ]]; then
        result="${years}年"
        if [[ "$remaining_days" -gt 0 ]]; then
            result="${result}${remaining_days}天"
        fi
    elif [[ "$days" -gt 0 ]]; then
        result="${days}天"
        if [[ "$remaining_hours" -gt 0 ]]; then
            result="${result}${remaining_hours}小时"
        fi
    else
        result="${hours}小时"
    fi
    
    echo "$result"
}

# 格式化容量显示
# 参数：$1 - 字节数
# 返回：人类可读的容量格式
format_capacity() {
    local bytes="$1"
    
    # 移除逗号和空格，只保留数字
    bytes=$(echo "$bytes" | sed 's/[^0-9]//g')
    
    if [[ -z "$bytes" || "$bytes" -eq 0 ]]; then
        echo "未知"
        return
    fi
    
    # 定义单位（使用二进制前缀）
    local units=("B" "KiB" "MiB" "GiB" "TiB" "PiB")
    local size=$bytes
    local unit_index=0
    
    # 计算合适的单位
    while [[ $size -gt 1024 && $unit_index -lt 5 ]]; do
        size=$((size / 1024))
        unit_index=$((unit_index + 1))
    done
    
    # 如果需要小数点，使用bc进行精确计算
    if [[ $unit_index -gt 0 ]]; then
        local divisor=1
        for ((i=0; i<unit_index; i++)); do
            divisor=$((divisor * 1024))
        done
        
        # 使用awk进行浮点计算
        local formatted=$(awk "BEGIN {printf \"%.2f\", $bytes/$divisor}")
        echo "$formatted ${units[$unit_index]}"
    else
        echo "$bytes ${units[$unit_index]}"
    fi
}

# 获取温度历史数据
# 参数：$1 - SMART数据
# 返回：最低温度和最高温度
get_temperature_history() {
    local smart_data="$1"
    local temp_line
    local min_temp=""
    local max_temp=""
    
    # 查找温度相关的行，优先使用Temperature_Celsius
    temp_line=$(echo "$smart_data" | grep -E "Temperature_Celsius|Airflow_Temperature_Cel" | head -n1)
    
    if [[ -n "$temp_line" ]]; then
        # 尝试从RAW_VALUE字段提取温度历史数据
        # 格式通常是: current (min/max min_temp/max_temp) 或 current min max ...
        
        # 检查是否包含括号格式的最小/最大值
        if [[ "$temp_line" == *"Min/Max"* ]]; then
            # 格式如: 33 (Min/Max 18/52)
            min_temp=$(echo "$temp_line" | sed -n 's/.*Min\/Max[^0-9]*\([0-9]\+\)\/\([0-9]\+\).*/\1/p')
            max_temp=$(echo "$temp_line" | sed -n 's/.*Min\/Max[^0-9]*\([0-9]\+\)\/\([0-9]\+\).*/\2/p')
        else
            # 提取RAW_VALUE字段（最后一个字段，可能包含括号）
            local raw_value=$(echo "$temp_line" | awk '{for(i=10;i<=NF;i++) printf "%s ", $i; print ""}' | sed 's/[()]//g')
            
            # 检查是否是空格分隔的数字格式
            if [[ "$raw_value" =~ ^[0-9]+[[:space:]]+[0-9]+[[:space:]]+[0-9]+ ]]; then
                # 格式如: 33 18 52 0 0 (current min max ...)
                local values=($raw_value)
                if [[ ${#values[@]} -ge 3 ]]; then
                    min_temp="${values[1]}"
                    max_temp="${values[2]}"
                fi
            fi
        fi
    fi
    
    echo "$min_temp $max_temp"
}

# 检查单个硬盘
# 功能：检查指定硬盘的详细健康状态
# 参数：$1 - 硬盘设备路径
# 返回：0-正常，1-有问题
check_disk() {
    local disk="$1"
    local device_name=$(basename "$disk")
    
    echo -e "\n${CYAN}==================== $disk ====================${NC}"
    
    # 获取SMART数据并分析退出码
    local smart_data
    smart_data=$(smartctl -a "$disk" 2>/dev/null)
    local smartctl_exit_code=$?
    
    # 分析smartctl退出码
    local status_warnings=()
    if (( smartctl_exit_code & 1 )); then
        echo -e "${RED}❌ 命令行参数错误${NC}"
        DEVICE_SUMMARY+=("${RED}❌ $device_name: 命令错误${NC}")
        return 1
    fi
    
    if (( smartctl_exit_code & 2 )); then
        echo -e "${RED}❌ 设备打开失败或设备处于低功耗模式${NC}"
        DEVICE_SUMMARY+=("${RED}❌ $device_name: 设备不可访问${NC}")
        return 1
    fi
    
    if (( smartctl_exit_code & 4 )); then
        echo -e "${RED}❌ SMART命令失败或数据校验错误${NC}"
        DEVICE_SUMMARY+=("${RED}❌ $device_name: SMART命令失败${NC}")
        return 1
    fi
    
    # 检查警告级别的状态
    if (( smartctl_exit_code & 8 )); then
        status_warnings+=("${RED}🚨 SMART状态显示硬盘故障${NC}")
    fi
    
    if (( smartctl_exit_code & 16 )); then
        status_warnings+=("${YELLOW}⚠️ 发现预失效属性超过阈值${NC}")
    fi
    
    if (( smartctl_exit_code & 32 )); then
        status_warnings+=("${YELLOW}⚠️ 历史上有属性超过阈值${NC}")
    fi
    
    if (( smartctl_exit_code & 64 )); then
        status_warnings+=("${YELLOW}⚠️ 设备错误日志包含错误记录${NC}")
    fi
    
    if (( smartctl_exit_code & 128 )); then
        status_warnings+=("${YELLOW}⚠️ 设备自检日志包含错误记录${NC}")
    fi
    
    # 显示退出码分析结果
    if [[ ${#status_warnings[@]} -gt 0 ]]; then
        echo -e "\n${BLUE}🔍 SMART诊断信息:${NC}"
        for warning in "${status_warnings[@]}"; do
            echo -e "   $warning"
        done
    fi
    
    # 如果没有数据但有警告，仍然尝试处理
    if [[ -z "$smart_data" ]]; then
        echo -e "${RED}❌ 无法获取SMART数据${NC}"
        DEVICE_SUMMARY+=("${RED}❌ $device_name: 无数据${NC}")
        return 1
    fi
    
    # 提取基本信息
    local model=$(echo "$smart_data" | awk -F': ' '/Device Model:|Model Number:/ {print $2}' | head -n1 | xargs)
    local serial=$(echo "$smart_data" | awk -F': ' '/Serial Number:/ {print $2}' | head -n1 | xargs)
    local capacity=$(echo "$smart_data" | awk -F': ' '/User Capacity:/ {gsub(/\[.*/, "", $2); print $2}' | head -n1 | xargs)
    local health=$(echo "$smart_data" | grep "SMART overall-health" | cut -d: -f2 | xargs)
    
    # 显示基本信息
    echo -e "${BLUE}💾 硬盘信息:${NC}"
    echo -e "   型号: ${model:-未知}"
    echo -e "   序列号: ${serial:-未知}"
    if [[ -n "$capacity" && "$capacity" != "未知" ]]; then
        local human_readable=$(format_capacity "$capacity")
        echo -e "   容量: $human_readable ($capacity)"
    else
        echo -e "   容量: ${capacity:-未知}"
    fi
    
    # 显示健康状态
    echo -e "\n${BLUE}🔍 SMART状态:${NC}"
    if [[ "$health" == *"PASSED"* ]]; then
        echo -e "   总体状态: ${GREEN}✅ 通过${NC}"
    else
        echo -e "   总体状态: ${RED}❌ 失败${NC}"
    fi
    
    # 提取关键SMART数据
    local realloc=$(get_smart_value "$smart_data" "Reallocated_Sector_Ct")
    local pending=$(get_smart_value "$smart_data" "Current_Pending_Sector")
    local uncorrectable=$(get_smart_value "$smart_data" "Uncorrectable_Sector_Ct")
    local temp=$(get_smart_value "$smart_data" "Temperature_Celsius")
    local power_on=$(get_smart_value "$smart_data" "Power_On_Hours")
    local power_cycle=$(get_smart_value "$smart_data" "Power_Cycle_Count")
    
    # 显示扇区状态
    echo -e "\n${BLUE}💾 扇区状态:${NC}"
    if [[ "$realloc" -gt 10 ]]; then
        echo -e "   重映射扇区: ${RED}🚨 警告 ($realloc)${NC}"
    elif [[ "$realloc" -gt 0 ]]; then
        echo -e "   重映射扇区: ${YELLOW}⚠️ 注意 ($realloc)${NC}"
    else
        echo -e "   重映射扇区: ${GREEN}✅ 正常 ($realloc)${NC}"
    fi
    
    if [[ "$pending" -gt 0 ]]; then
        echo -e "   待处理扇区: ${RED}🚨 警告 ($pending)${NC}"
    else
        echo -e "   待处理扇区: ${GREEN}✅ 正常 ($pending)${NC}"
    fi
    
    if [[ "$uncorrectable" -gt 0 ]]; then
        echo -e "   不可修复扇区: ${RED}🚨 严重 ($uncorrectable)${NC}"
    else
        echo -e "   不可修复扇区: ${GREEN}✅ 正常 ($uncorrectable)${NC}"
    fi
    
    # 显示温度
    echo -e "\n${BLUE}🌡️ 温度监控:${NC}"
    
    # 获取温度历史数据
    local temp_history=($(get_temperature_history "$smart_data"))
    local min_temp="${temp_history[0]}"
    local max_temp="${temp_history[1]}"
    
    # 显示当前温度
    local temp_display=""
    if [[ "$temp" -gt 70 ]]; then
        temp_display="${RED}🔥 过热 (${temp}°C)${NC}"
    elif [[ "$temp" -gt 60 ]]; then
        temp_display="${YELLOW}⚠️ 偏高 (${temp}°C)${NC}"
    elif [[ "$temp" -gt 0 ]]; then
        temp_display="${GREEN}✅ 正常 (${temp}°C)${NC}"
    else
        temp_display="${YELLOW}❓ 未知${NC}"
    fi
    
    # 添加历史温度信息
    if [[ -n "$min_temp" && -n "$max_temp" && "$min_temp" != "0" && "$max_temp" != "0" ]]; then
        echo -e "   当前温度: $temp_display (历史: ${min_temp}°C ~ ${max_temp}°C)"
    else
        echo -e "   当前温度: $temp_display"
    fi
    
    # 显示使用统计
    echo -e "\n${BLUE}📊 使用统计:${NC}"
    if [[ "$power_on" -gt 0 ]]; then
        local formatted_time=$(format_hours "$power_on")
        echo -e "   通电时间: $formatted_time (${power_on}小时)"
    fi
    
    if [[ "$power_cycle" -gt 0 ]]; then
        echo -e "   开关机次数: $power_cycle 次"
    fi
    
    # 计算健康评分
    local health_score=$(calculate_health_score "$realloc" "$pending" "$temp")
    echo -e "\n${BLUE}🏥 健康评分:${NC}"
    if [[ "$health_score" -ge 90 ]]; then
        echo -e "   综合评分: ${GREEN}优秀 (${health_score}/100)${NC}"
    elif [[ "$health_score" -ge 70 ]]; then
        echo -e "   综合评分: ${YELLOW}良好 (${health_score}/100)${NC}"
    elif [[ "$health_score" -ge 50 ]]; then
        echo -e "   综合评分: ${YELLOW}一般 (${health_score}/100)${NC}"
    else
        echo -e "   综合评分: ${RED}需要关注 (${health_score}/100)${NC}"
    fi
    
    # 给出建议
    echo -e "\n${BLUE}💡 建议:${NC}"
    if [[ "$health_score" -lt 70 ]]; then
        echo -e "   ${YELLOW}⚠️ 建议备份重要数据${NC}"
    fi
    if [[ "$temp" -gt 60 ]]; then
        echo -e "   ${YELLOW}⚠️ 建议改善散热条件${NC}"
    fi
    if [[ "$realloc" -gt 10 || "$pending" -gt 0 || "$uncorrectable" -gt 0 ]]; then
        echo -e "   ${RED}🚨 建议尽快更换硬盘${NC}"
    fi
    if [[ "$health_score" -ge 90 && "$temp" -le 50 ]]; then
        echo -e "   ${GREEN}✅ 硬盘状态良好，继续正常使用${NC}"
    fi
    
    echo -e "\n${CYAN}================================================${NC}"
    
    # 收集设备状态用于总览，考虑smartctl退出码
    local device_status="正常"
    local device_color="$GREEN"
    
    # 根据smartctl退出码和健康评分确定设备状态
    if (( smartctl_exit_code & 8 )) || [[ "$health_score" -lt 50 ]] || [[ "$uncorrectable" -gt 0 ]]; then
        device_status="严重"
        device_color="$RED"
    elif (( smartctl_exit_code & 80 )) || [[ "$health_score" -lt 70 ]] || [[ "$realloc" -gt 10 ]] || [[ "$pending" -gt 0 ]] || [[ "$temp" -gt 70 ]]; then
        device_status="警告"
        device_color="$YELLOW"
    fi
    
    # 添加退出码信息到设备摘要
    local exit_code_info=""
    if [[ "$smartctl_exit_code" -ne 0 ]]; then
        exit_code_info=" (退出码:$smartctl_exit_code)"
    fi
    
    DEVICE_SUMMARY+=("${device_color}${device_status} $device_name: 评分${health_score}/100${exit_code_info}${NC}")
    
    # 返回状态
    if [[ "$device_status" != "正常" ]]; then
        return 1
    fi
    return 0
}

# 收集设备状态摘要
# 功能：收集设备状态信息用于最终总览
# 参数：$1 - 设备名，$2 - 健康评分，$3 - 温度，$4 - 重映射扇区，$5 - 待处理扇区
collect_device_summary() {
    local device="$1"
    local score="$2"
    local temp="$3"
    local realloc="$4"
    local pending="$5"
    
    local status_icon="✅"
    local status_color="$GREEN"
    local status_text="正常"
    
    # 判断状态级别
    if [[ "$score" -lt 50 || "$realloc" -gt 10 || "$pending" -gt 0 ]]; then
        status_icon="🚨"
        status_color="$RED"
        status_text="严重"
    elif [[ "$score" -lt 70 || "$realloc" -gt 0 || "$temp" -gt 60 ]]; then
        status_icon="⚠️"
        status_color="$YELLOW"
        status_text="警告"
    fi
    
    # 构建摘要信息
    local summary="${status_color}${status_icon} ${device}: ${status_text} (评分:${score}/100"
    if [[ "$temp" -gt 0 ]]; then
        summary="${summary}, 温度:${temp}°C"
    fi
    summary="${summary})${NC}"
    
    DEVICE_SUMMARY+=("$summary")
}

# 扫描硬盘设备
# 功能：自动发现系统中的硬盘设备
# 返回：硬盘设备列表
scan_disks() {
    local disks=()
    
    # 扫描SATA/SAS硬盘 (sda, sdb, etc.)
    for disk in /dev/sd[a-z] /dev/sd[a-z][a-z]; do
        [[ -e "$disk" ]] && disks+=("$disk")
    done
    
    # 扫描NVMe硬盘
    for disk in /dev/nvme[0-9]n[0-9]; do
        [[ -e "$disk" ]] && disks+=("$disk")
    done
    
    printf '%s\n' "${disks[@]}"
}

# 显示设备状态总览
# 功能：显示所有检查设备的状态摘要
show_device_summary() {
    if [[ ${#DEVICE_SUMMARY[@]} -eq 0 ]]; then
        echo -e "${YELLOW}⚠️ 没有检查到任何设备${NC}"
        return
    fi
    
    echo -e "\n${CYAN}==================== 设备状态总览 ====================${NC}"
    
    # 统计各状态设备数量
    local total=${#DEVICE_SUMMARY[@]}
    local critical=0
    local warning=0
    local normal=0
    
    for summary in "${DEVICE_SUMMARY[@]}"; do
        if [[ "$summary" == *"严重"* ]]; then
            ((critical++))
        elif [[ "$summary" == *"警告"* ]]; then
            ((warning++))
        else
            ((normal++))
        fi
    done
    
    # 显示统计信息
    echo -e "${BLUE}📊 状态统计:${NC}"
    echo -e "   总设备数: $total"
    [[ $normal -gt 0 ]] && echo -e "   ${GREEN}✅ 正常: $normal${NC}"
    [[ $warning -gt 0 ]] && echo -e "   ${YELLOW}⚠️ 警告: $warning${NC}"
    [[ $critical -gt 0 ]] && echo -e "   ${RED}🚨 严重: $critical${NC}"
    
    # 显示设备列表
    echo -e "\n${BLUE}💾 设备详情:${NC}"
    for summary in "${DEVICE_SUMMARY[@]}"; do
        echo -e "   $summary"
    done
    
    echo -e "\n${CYAN}================================================${NC}"
}

# 主函数
# 功能：脚本主入口，协调所有检查流程
main() {
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}    硬盘健康监控系统 v${SCRIPT_VERSION}${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo -e "开始时间: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""
    
    # 检查依赖
    if ! check_smartctl; then
        exit 1
    fi
    
    # 扫描硬盘
    echo -e "${BLUE}🔍 正在扫描硬盘设备...${NC}"
    local disks
    readarray -t disks < <(scan_disks)
    
    if [[ ${#disks[@]} -eq 0 ]]; then
        echo -e "${YELLOW}⚠️ 未发现任何硬盘设备${NC}"
        exit 1
    fi
    
    echo -e "${CYAN}发现 ${#disks[@]} 个硬盘设备: ${disks[*]}${NC}"
    
    # 检查每个硬盘
    local failed_count=0
    local start_time=$(date +%s)
    
    for disk in "${disks[@]}"; do
        if ! check_disk "$disk"; then
            ((failed_count++))
        fi
    done
    
    # 显示设备状态总览
    show_device_summary
    
    # 显示最终结果
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    echo -e "\n${GREEN}========================================${NC}"
    echo -e "${GREEN}检查完成${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo -e "检查设备: ${#disks[@]} 个"
    [[ $failed_count -gt 0 ]] && echo -e "问题设备: ${RED}$failed_count${NC} 个"
    echo -e "检查耗时: $duration 秒"
    echo -e "完成时间: $(date '+%Y-%m-%d %H:%M:%S')"
    
    # 返回适当的退出码
    if [[ $failed_count -eq 0 ]]; then
        echo -e "\n${GREEN}✅ 所有硬盘状态正常！${NC}"
        exit 0
    else
        echo -e "\n${YELLOW}⚠️ 发现 $failed_count 个硬盘存在问题，请及时处理！${NC}"
        exit 1
    fi
}

# 显示帮助信息
show_help() {
    cat << EOF
硬盘健康监控系统 v${SCRIPT_VERSION} - 简化版

功能特性:
  ✅ 自动扫描SATA/SAS和NVMe硬盘
  ✅ SMART健康状态检查
  ✅ 温度监控和扇区状态检测
  ✅ 简化的健康评分系统
  ✅ 彩色输出和状态总览
  ✅ 简洁易懂的代码结构

使用方法:
  $0              # 检查所有硬盘
  $0 -h|--help    # 显示帮助信息
  $0 -v|--version # 显示版本信息

注意事项:
  - 需要安装smartmontools工具包
  - 建议以root权限运行以获取完整信息
  - 支持SATA/SAS和NVMe硬盘

EOF
}

# 处理命令行参数
case "${1:-}" in
    -h|--help)
        show_help
        exit 0
        ;;
    -v|--version)
        echo "硬盘健康监控系统 v${SCRIPT_VERSION} - 简化版"
        exit 0
        ;;
    "")
        # 无参数，运行主程序
        main
        ;;
    *)
        echo "未知选项: $1"
        echo "使用 $0 --help 查看帮助信息"
        exit 1
        ;;
esac
