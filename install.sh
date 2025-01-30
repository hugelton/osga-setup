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
    libtiff6 \
    python3-pil \
    python3-rpi.gpio \
    luajit \
    libluajit-5.1-dev

# /boot/firmware/config.txtの設定
echo "Configuring system settings..."
if ! grep -q "dtoverlay=rpi-display" /boot/firmware/config.txt; then
    sudo tee -a /boot/firmware/config.txt << EOF

# OSGA Display Settings
dtparam=spi=on
dtoverlay=rpi-display,speed=48000000,rotate=270
dtparam=spi_buffer_size=32768

# HDMI Settings
hdmi_force_hotplug=1
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

# メインスクリプトの作成
echo "Creating main script..."
cat > main.py << 'EOF'
from src.kage import Kage
from src.kage.lua_binding import KageLuaEngine

def main():
    kage = Kage()
    engine = KageLuaEngine(kage)
    engine.load_script('scripts/tests/kage_test.lua')
    engine.run()

if __name__ == "__main__":
    main()
EOF

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

# 権限の設定
sudo usermod -a -G video,spi,gpio pi

# サービスの有効化
sudo systemctl enable osga.service

echo "Installation completed!"
echo "Please reboot the system to apply all settings."
