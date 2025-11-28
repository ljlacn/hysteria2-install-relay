#!/bin/bash

# ==========================
#   Hysteria2 Relay Installer
# ==========================

HY_PATH="/usr/local/bin/hysteria2"
SERVICE_NAME="hysteria2-relay"
CONFIG_DIR="/etc/hysteria2"
CONFIG_FILE="$CONFIG_DIR/relay.yaml"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

check_root() {
    if [ "$(id -u)" != "0" ]; then
        echo -e "${RED}请以 root 用户运行此脚本${NC}"
        exit 1
    fi
}

install_hysteria2() {
    echo -e "${GREEN}开始安装 Hysteria2 ...${NC}"

    mkdir -p $CONFIG_DIR

    if [[ ! -f "$HY_PATH" ]]; then
        echo -e "${YELLOW}下载 Hysteria2 ...${NC}"
        wget -O $HY_PATH https://github.com/apernet/hysteria/releases/latest/download/hysteria-linux-amd64
        chmod +x $HY_PATH
    fi

    echo -e "${GREEN}创建 relay 配置文件${NC}"
    read -p "请输入美国服务器地址（例如 us.xxx.com:443）: " US_SERVER
    read -p "请输入密码: " PASSWORD

    cat > $CONFIG_FILE <<EOF
listen: :3200

relay:
  server: $US_SERVER
  password: "$PASSWORD"
  obfs:
    type: salamander
EOF

    echo -e "${GREEN}创建 systemd 服务${NC}"
    cat > /etc/systemd/system/$SERVICE_NAME.service <<EOF
[Unit]
Description=Hysteria2 Relay Service
After=network.target

[Service]
ExecStart=$HY_PATH relay -c $CONFIG_FILE
Restart=on-failure
LimitNOFILE=51200

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable $SERVICE_NAME
    systemctl restart $SERVICE_NAME

    echo -e "${GREEN}Hysteria2 中转安装完成！${NC}"
    echo ""
    echo "配置文件：$CONFIG_FILE"
    echo "启动：systemctl start $SERVICE_NAME"
    echo "查看日志：journalctl -u $SERVICE_NAME -f"
}

uninstall_hysteria2() {
    echo -e "${RED}正在卸载 Hysteria2 Relay ...${NC}"
    systemctl stop $SERVICE_NAME
    systemctl disable $SERVICE_NAME
    rm -f /etc/systemd/system/$SERVICE_NAME.service
    systemctl daemon-reload

    rm -f $HY_PATH
    rm -rf $CONFIG_DIR

    echo -e "${GREEN}卸载完成${NC}"
}

show_info() {
    echo -e "${GREEN}--- 当前安装信息 ---${NC}"
    
    if [[ -f "$HY_PATH" ]]; then
        echo "Hysteria2 执行文件：$HY_PATH"
        echo "版本："
        $HY_PATH -v
    else
        echo -e "${RED}未安装 Hysteria2${NC}"
    fi

    if [[ -f "$CONFIG_FILE" ]]; then
        echo ""
        echo "配置文件内容："
        cat $CONFIG_FILE
    else
        echo -e "${RED}未找到 relay 配置文件${NC}"
    fi

    echo ""
    systemctl status $SERVICE_NAME --no-pager
}

menu() {
    clear
    echo -e "${GREEN}==========================================${NC}"
    echo -e "${GREEN}          Hysteria2 Relay 管理脚本        ${NC}"
    echo -e "${GREEN}==========================================${NC}"
    echo ""
    echo "1. 安装 Hysteria2 Relay"
    echo "2. 卸载 Hysteria2 Relay"
    echo "3. 查看当前安装信息"
    echo "4. 退出"
    echo ""
    read -p "请输入选择：" num

    case "$num" in
        1)
            install_hysteria2
            ;;
        2)
            uninstall_hysteria2
            ;;
        3)
            show_info
            ;;
        4)
            exit 0
            ;;
        *)
            echo -e "${RED}无效输入${NC}"
            ;;
    esac
}

check_root
menu
