#!/bin/bash

mkdir -p /var/www/html
LOG_FILE="/var/www/html/reinstall.log"
HTML_FILE="/var/www/html/index.html"

# Start web server di port 80
nohup python3 -m http.server 80 --directory /var/www/html > /dev/null 2>&1 &

# HTML Tampilan Awal
cat <<EOF > $HTML_FILE
<html>
  <head>
    <meta http-equiv="refresh" content="5">
    <style>
      body {
        font-family: Arial, sans-serif;
        background: #f0f0f0;
        text-align: center;
        padding-top: 60px;
      }
      h1 {
        font-size: 28pt;
        color: #2c3e50;
      }
      h2 {
        font-size: 16pt;
        color: #666;
        margin-bottom: 40px;
      }
      .progress-container {
        width: 60%;
        height: 30px;
        background-color: #eee;
        border-radius: 15px;
        margin: 0 auto;
        box-shadow: inset 0 1px 3px rgba(0,0,0,0.2);
      }
      .progress-bar {
        height: 100%;
        width: 0%;
        background-color: #f1c40f;
        border-radius: 15px;
        text-align: center;
        line-height: 30px;
        color: #000;
        font-weight: bold;
        transition: width 0.5s ease;
      }
    </style>
  </head>
  <body>
    <h1>Selamat Datang di Haf.id Store</h1>
    <h2>Mohon ditunggu, proses sedang berjalan...</h2>

    <div class="progress-container">
      <div class="progress-bar" id="bar">0%</div>
    </div>

    <script>
      async function updateProgress() {
        try {
          const res = await fetch('reinstall.log');
          const text = await res.text();
          const lines = text.split('\\n');
          const percent = Math.min(Math.floor(lines.length / 2), 100);
          const bar = document.getElementById("bar");
          bar.style.width = percent + "%";
          bar.innerText = percent + "%";
        } catch (e) {
          console.error("Progress fetch error:", e);
        }
      }

      updateProgress();
      setInterval(updateProgress, 5000);
    </script>
  </body>
</html>
EOF

# Unduh skrip reinstall
curl -O https://raw.githubusercontent.com/tehafidh/reinstall/refs/heads/main/reinstall.sh || wget -O reinstall.sh https://raw.githubusercontent.com/kripul/reinstall/main/reinstall.sh

# Jalankan proses dan simpan log ke reinstall.log
(
    > $LOG_FILE
    bash reinstall.sh dd \
        --rdp-port 1 \
        --password 'Hafidh!' \
        --img 'http://rdpadmin.me/a/filea.gz' >> $LOG_FILE 2>&1

    echo "" >> $LOG_FILE
    echo "✅ Proses reinstall selesai. Silakan tunggu dan login via RDP." >> $LOG_FILE

    sleep 10
    reboot
) &
