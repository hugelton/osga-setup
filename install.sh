#!/bin/bash

echo "Starting OSGA installation..."

# 必要なパッケージのインストール
echo "Installing required packages..."
sudo apt-get update
sudo apt-get install -y \
    python3-pip \
    python3-venv \
    git \
    libjpeg-dev \
    zlib1g-dev \
    libopenjp2-7 \     
    libopenjp2-7-dev \ 
    libtiff6         \ 
        python3-pil

# HDMI解像度の設定
echo "Configuring HDMI resolution..."
if ! grep -q "hdmi_cvt=320 240" /boot/firmware/config.txt; then
    sudo tee -a /boot/firmware/config.txt << EOF

# OSGA Display Settings HDMI
hdmi_force_hotplug=1
hdmi_group=2
hdmi_mode=87
hdmi_cvt=320 240 60 1 0 0 0

# LCD Framebuffer 
dtoverlay=fb1
dtparam=fb1_width=320
dtparam=fb1_height=240
dtparam=fb1_depth=16
EOF
fi

# フレームバッファの設定
echo "Configuring framebuffer..."
if ! grep -q "dtoverlay=fb" /boot/firmware/config.txt; then
    sudo tee -a /boot/firmware/config.txt << EOF
dtoverlay=fb
EOF
fi

# プロジェクトのクローンと環境設定
echo "Cloning OSGA repository..."
cd /home/pi
git clone https://github.com/hugelton/osga.git

# Python仮想環境のセットアップ
echo "Setting up Python virtual environment..."
cd osga
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# systemdサービスの設定
echo "Setting up systemd service..."
sudo tee /etc/systemd/system/osga.service << EOF
[Unit]
Description=OSGA (Organic Sound Generation Assembly)
After=network.target

[Service]
Type=simple
User=pi
WorkingDirectory=/home/pi/osga
Environment="PATH=/home/pi/osga/venv/bin:$PATH"
Environment="FRAMEBUFFER=/dev/fb0"
ExecStart=/home/pi/osga/venv/bin/python3 main.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# ビデオグループにユーザーを追加
sudo usermod -a -G video pi

# サービスの有効化
sudo systemctl enable osga.service

echo "Installation completed!"
echo "Please reboot the system to apply all settings."
echo "After reboot, the service will start automatically."
