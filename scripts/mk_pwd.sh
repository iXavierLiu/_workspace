#!/bin/sh
# mk_pwd.sh - 生成一个32字符的随机密码

# 验证随机：
# 运行一万次，统计每个字符出现的次数
# for i in {1..10000}; do sh mk_pwd.sh >> pwd.txt ; done
# cat pwd.txt| fold -w1 | sort | uniq -c

< /dev/urandom tr -dc 'A-Za-z0-9!@#$%^*_+-=[]{}|;:,./?~' | head -c 32; echo
