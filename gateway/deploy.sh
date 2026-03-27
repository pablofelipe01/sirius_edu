#!/bin/bash
# Deploy del handler educativo al Jetson Orin Nano
# Uso: ./deploy.sh [IP] [PASSWORD]

JETSON_IP="${1:-192.168.68.141}"
JETSON_USER="pablo"
JETSON_PASS="${2:-DaMa0713}"
GATEWAY_DIR="~/agro_gateway"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== Deploy Sirius Edu Handler ==="
echo "Jetson: $JETSON_USER@$JETSON_IP"

# Verificar conectividad
echo "Verificando conexion..."
if ! ping -c 1 -W 3 "$JETSON_IP" > /dev/null 2>&1; then
    echo "ERROR: Jetson no responde en $JETSON_IP"
    exit 1
fi
echo "OK - Jetson en linea"

# Copiar handler
echo "Copiando edu.py..."
sshpass -p "$JETSON_PASS" scp "$SCRIPT_DIR/handlers/edu.py" "$JETSON_USER@$JETSON_IP:$GATEWAY_DIR/handlers/"

# Copiar curriculos
echo "Copiando curriculos..."
sshpass -p "$JETSON_PASS" ssh "$JETSON_USER@$JETSON_IP" "mkdir -p $GATEWAY_DIR/curriculos/ciencias_naturales $GATEWAY_DIR/curriculos/matematicas"
sshpass -p "$JETSON_PASS" scp "$SCRIPT_DIR/curriculos/ciencias_naturales/grado2.json" "$JETSON_USER@$JETSON_IP:$GATEWAY_DIR/curriculos/ciencias_naturales/"
sshpass -p "$JETSON_PASS" scp "$SCRIPT_DIR/curriculos/matematicas/grado2.json" "$JETSON_USER@$JETSON_IP:$GATEWAY_DIR/curriculos/matematicas/"

# Aplicar patch al mesh_gateway.py
echo "Aplicando patch al gateway..."
sshpass -p "$JETSON_PASS" ssh "$JETSON_USER@$JETSON_IP" << 'REMOTE_SCRIPT'
cd ~/agro_gateway

# Backup
cp mesh_gateway.py mesh_gateway.py.backup_$(date +%Y%m%d_%H%M%S)

# 1. Agregar import de edu si no existe
if ! grep -q "from handlers import.*edu" mesh_gateway.py; then
    sed -i 's/from handlers import registro, siembra, claude_ai, telegram_bridge, image/from handlers import registro, siembra, claude_ai, telegram_bridge, image, edu/' mesh_gateway.py
    echo "  + import edu agregado"
fi

# 2. Agregar edu.init en init_handlers si no existe
if ! grep -q "edu.init" mesh_gateway.py; then
    sed -i '/image.init(ANTHROPIC_API_KEY)/a\    edu.init(ANTHROPIC_API_KEY)' mesh_gateway.py
    echo "  + edu.init() agregado"
fi

# 3. Agregar rutas educativas antes del bloque @claude si no existe
if ! grep -q "edu_prefixes" mesh_gateway.py; then
    sed -i '/# Claude AI/i\        # Educativo\n        edu_prefixes = ("PREGUNTA_IA|", "ENTREGA|", "LECCION|", "EVAL_PROF|",\n                       "PERFIL_UPDATE|", "SYNC_REQ|", "TAREA|")\n        if any(text.startswith(p) for p in edu_prefixes):\n            logging.info(f"📚 Mensaje EDU detectado")\n            edu.handle(text, from_id, from_num, send_fn, publish_mqtt_msg)\n            return\n' mesh_gateway.py
    echo "  + rutas EDU agregadas"
fi

echo "Patch aplicado."
REMOTE_SCRIPT

# Reiniciar servicio
echo "Reiniciando mesh-gateway.service..."
sshpass -p "$JETSON_PASS" ssh "$JETSON_USER@$JETSON_IP" "sudo systemctl restart mesh-gateway.service && sleep 2 && sudo systemctl status mesh-gateway.service --no-pager | head -15"

# Verificar
echo ""
echo "Verificando logs..."
sshpass -p "$JETSON_PASS" ssh "$JETSON_USER@$JETSON_IP" "journalctl -u mesh-gateway.service --no-pager -n 10"

echo ""
echo "=== Deploy completado ==="
