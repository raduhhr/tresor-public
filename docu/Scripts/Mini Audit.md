ssh local-node 'bash -s' <<'EOF' 
#!/bin/bash 
set -euo pipefail

echo 
echo "🔍 TRESOR SYSTEM AUDIT ($(date))" 
echo "=====================================" 
echo

\# --- System Summary --- 
echo "🧠 Host Summary:" 
hostnamectl | grep -E 'Static|Operating|Kernel|Architecture' 
echo 
uptime -p 
echo

\# --- User Accounts --- 
echo "👥 Users:" 
grep -E 'user|ansible|admin' /etc/passwd || true 
echo

\# --- Filesystem (/mnt) --- 
echo "💾 Mounted Storage (/mnt):" 
if \[ -d /mnt \]; then 
    for dir in /mnt/\*; do 
        \[ -d "$dir" \] || continue 
        echo "📁 $(basename "$dir")/" 
        for sub in "$dir"/\*; do 
            \[ -d "$sub" \] && echo " └── $(basename "$sub")/" 
        done 
    done 
else 
    echo "⚠️ /mnt not found." 
fi 
echo

\# --- Network Info --- 
echo "🌐 Network Overview:" 
ip -brief addr show | sed 's/^/ /' 
echo 
echo "🌍 Default route:" 
ip route show default | sed 's/^/ /' 
echo 
echo "📡 Listening Ports (LAN-relevant):" 
ss -tuln | grep -E ':22|:80|:443|:25565|:3000|:9090' | sed 's/^/ /' || echo " None found." 
echo

\# --- Firewall --- 
echo "🧱 Firewall Status:" 
if command -v ufw >/dev/null 2>&1; then 
    sudo ufw status verbose || true 
else 
    echo "⚠️ UFW not installed, showing iptables DOCKER-USER chain instead:" 
    sudo iptables -L DOCKER-USER -n -v | sed 's/^/ /' 
fi 
echo

\# --- Docker Status --- 
echo "🐳 Docker Status:" 
if systemctl is-active --quiet docker; then 
    echo "✅ Docker service is active" 
else 
    echo "❌ Docker service is inactive" 
fi 
echo

\# --- Containers --- 
echo "📦 Running Containers:" 
docker ps --format "table {{.Names}}\\t{{.Image}}\\t{{.Status}}" || echo " Docker not available." 
echo

\# --- Docker Networks --- 
echo "🌐 Docker Networks:" 
if docker network ls >/dev/null 2>&1; then 
    for net in $(docker network ls --format '{{.Name}}'); do 
        echo "→ $net:" 
        attached=$(docker network inspect "$net" --format '{{range .Containers}}{{.Name}} {{end}}') 
        if \[ -z "$attached" \]; then 
            echo " (no containers attached)" 
        else 
            for c in $attached; do 
                echo " └── $c" 
            done 
        fi 
    done 
else 
    echo "⚠️ Docker not installed or not running." 
fi 
echo

\# --- Container UID check --- 
echo "🐚 Checking for root containers:" 
if docker ps -q | grep -q .; then 
    while read -r cid; do 
        cname=$(docker inspect --format '{{.Name}}' "$cid" | sed 's|/||') 
        uid=$(docker inspect --format '{{.Config.User}}' "$cid") 
        if \[\[ -z "$uid" || "$uid" == "0" \]\]; then 
            echo "⚠️ $cname runs as root" 
        else 
            echo "✅ $cname runs as UID=$uid" 
        fi 
    done < <(docker ps -q) 
else 
    echo "ℹ️ No containers running." 
fi 
echo

\# --- Minecraft Port --- 
echo "🎮 Minecraft Port (25565):" 
if ss -tln '( sport = :25565 )' | grep -q 25565; then 
    echo "✅ Port 25565 open on Tresor" 
else 
    echo "❌ Port 25565 closed or filtered" 
fi 
echo

echo "==== AUDIT COMPLETE ($(date)) ====" 
echo "=====================================" 
EOF