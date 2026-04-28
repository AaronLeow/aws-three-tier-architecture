#!/bin/bash
dnf update -y
dnf install -y nginx python3 python3-pip

python3 -m pip install flask pymysql

mkdir -p /app
cat > /app/app.py << 'PYEOF'
from flask import Flask
import pymysql
import os

app = Flask(__name__)

DB_HOST = os.environ.get('DB_HOST', '')
DB_USER = os.environ.get('DB_USER', 'admin')
DB_PASS = os.environ.get('DB_PASS', '')
DB_NAME = os.environ.get('DB_NAME', 'threetierdb')

@app.route('/')
def index():
    try:
        conn = pymysql.connect(host=DB_HOST, user=DB_USER, password=DB_PASS, database=DB_NAME)
        cursor = conn.cursor()
        cursor.execute("SELECT VERSION()")
        version = cursor.fetchone()[0]
        conn.close()
        db_status = f"Connected to MySQL {version}"
        status_color = "#00d4aa"
    except Exception as e:
        db_status = f"DB Connection Failed: {str(e)}"
        status_color = "#ff4444"

    return f"""
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="UTF-8">
        <title>Three-Tier Architecture</title>
        <style>
            body {{ font-family: Arial, sans-serif; background: #0f1117; color: #e8e8f0;
                   display: flex; justify-content: center; align-items: center;
                   height: 100vh; margin: 0; }}
            .card {{ background: #1a1a2e; border: 1px solid #00d4aa;
                    border-radius: 12px; padding: 40px; text-align: center; min-width: 400px; }}
            h1 {{ color: #00d4aa; }}
            .db-status {{ color: {status_color}; margin-top: 20px;
                         padding: 10px; border: 1px solid {status_color};
                         border-radius: 6px; font-size: 14px; }}
            p {{ color: #9999b0; }}
        </style>
    </head>
    <body>
        <div class="card">
            <h1>&#9989; Three-Tier Architecture</h1>
            <p>AWS Portfolio Project &#8212; Aaron Leow</p>
            <p>EC2 Web Tier | Private Subnet | Behind ALB</p>
            <div class="db-status">&#128196; {db_status}</div>
        </div>
    </body>
    </html>
    """

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=80)
PYEOF

cat > /etc/systemd/system/flaskapp.service << 'SVCEOF'
[Unit]
Description=Flask Three-Tier App
After=network.target

[Service]
ExecStart=/usr/bin/python3 /app/app.py
Restart=always
Environment="DB_HOST=${db_host}"
Environment="DB_USER=admin"
Environment="DB_PASS=${db_password}"
Environment="DB_NAME=threetierdb"

[Install]
WantedBy=multi-user.target
SVCEOF

systemctl daemon-reload
systemctl start flaskapp
systemctl enable flaskapp