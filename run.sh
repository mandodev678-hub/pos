#!/bin/bash
# ╔══════════════════════════════════════════╗
# ║     تشغيل نظام زمام POS الكامل         ║
# ╚══════════════════════════════════════════╝

# تحديد المسارات
export PATH=/home/elwens/Desktop/POS/.tools/node/bin:$PATH
export HOME=/home/elwens/Desktop/POS/.tools/home
cd /home/elwens/Desktop/POS

echo ""
echo "══════════════════════════════════════════════"
echo "  🚀 تشغيل نظام زمام POS"
echo "══════════════════════════════════════════════"
echo ""
echo "  🌐 Website:  http://localhost:3000"
echo "  🖥️  POS:      http://localhost:3002"
echo "  🍳 KDS:      http://localhost:3003"
echo "  📡 API:      http://localhost:3001/api"
echo ""
echo "  بيانات الدخول: admin / admin123"
echo ""
echo "══════════════════════════════════════════════"
echo "  اضغط Ctrl+C لإيقاف الخوادم"
echo "══════════════════════════════════════════════"
echo ""

node /home/elwens/Desktop/POS/start-all.js
