# install.sh - RPiに直接配置して1回だけ実行
#!/bin/bash

echo "Starting OSGA installation..."

# 必要なパッケージのインストール
echo "Installing required packages..."
sudo apt-get update
sudo apt-get install -y \
    python3-pip \
    python3-venv \
    python3-pygame \
    git

# HDMI解像度の設定
echo "Configuring HDMI resolution..."
if ! grep -q "hdmi_cvt=320 240" /boot/config.txt; then
    sudo tee -a /boot/config.txt << EOF

# OSGA Display Settings
hdmi_force_hotplug=1
hdmi_group=2
hdmi_mode=87
hdmi_cvt=320 240 60 1 0 0 0
EOF
fi

# プロジェクトのクローンと環境設定
echo "Cloning OSGA repository..."
cd /home/pi
git clone git@github.com:hugelton/osga.git

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
Environment="DISPLAY=:0"
ExecStart=/home/pi/osga/venv/bin/python3 main.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# サービスの有効化
sudo systemctl enable osga.service

echo "Installation completed!"
echo "Please reboot the system to apply HDMI settings."
echo "After reboot, the service will start automatically."