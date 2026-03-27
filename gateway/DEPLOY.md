# Deploy del Handler Educativo en el Gateway

## Paso 1: Copiar archivos al Jetson

```bash
# Desde tu Mac:
scp gateway/handlers/edu.py pablo@192.168.68.141:~/agro_gateway/handlers/
scp -r gateway/curriculos/ pablo@192.168.68.141:~/agro_gateway/
```

## Paso 2: Editar mesh_gateway.py en el Jetson

SSH al Jetson y agregar el import y las rutas educativas:

```bash
ssh pablo@192.168.68.141
cd ~/agro_gateway
nano mesh_gateway.py
```

### Cambio 1 — Agregar import (linea 11, con los otros imports):
```python
from handlers import registro, siembra, claude_ai, telegram_bridge, image, edu
```

### Cambio 2 — Agregar init en init_handlers():
```python
def init_handlers():
    claude_ai.init(ANTHROPIC_API_KEY)
    image.init(ANTHROPIC_API_KEY)
    edu.init(ANTHROPIC_API_KEY)  # <-- AGREGAR
    logging.info("✓ Handlers inicializados")
```

### Cambio 3 — Agregar rutas en process_mesh_message(), ANTES del bloque de Claude:
```python
        # Educativo (NUEVO)
        edu_prefixes = ('PREGUNTA_IA|', 'ENTREGA|', 'LECCION|', 'EVAL_PROF|',
                       'PERFIL_UPDATE|', 'SYNC_REQ|', 'TAREA|')
        if any(text.startswith(p) for p in edu_prefixes):
            logging.info(f"📚 Mensaje EDU detectado")
            edu.handle(text, from_id, from_num, send_fn, publish_mqtt_msg)
            return
```

### Cambio 4 (opcional) — Agregar sync periodico en main():
```python
    # Despues del while True:
    import threading
    def periodic_sync():
        while True:
            time.sleep(300)  # cada 5 minutos
            try:
                airtable_token = os.getenv('AIRTABLE_API_TOKEN', '')
                edu_base_id = os.getenv('AIRTABLE_EDU_BASE_ID', '')
                if airtable_token and edu_base_id:
                    edu.sync_to_airtable(airtable_token, edu_base_id)
            except Exception as e:
                logging.error(f"Error sync edu: {e}")

    sync_thread = threading.Thread(target=periodic_sync, daemon=True)
    sync_thread.start()
```

## Paso 3: Agregar variable de entorno para Airtable EDU

```bash
sudo nano /etc/systemd/system/mesh-gateway.service
```

Agregar bajo las variables existentes:
```
Environment="AIRTABLE_EDU_BASE_ID=appXXXXXXXXXXXXXX"
```

## Paso 4: Reiniciar el servicio

```bash
sudo systemctl daemon-reload
sudo systemctl restart mesh-gateway.service
sudo systemctl status mesh-gateway.service
journalctl -u mesh-gateway.service -f  # Ver logs en vivo
```

## Verificar

Buscar en los logs:
```
✓ Handler EDU inicializado (local-first)
✓ Base de datos EDU lista: /home/pablo/agro_gateway/edu_data.db
```

## Airtable

Crear una nueva base en Airtable con estas tablas:
- Estudiantes
- Lecciones
- Tareas
- Entregas
- Conversaciones IA

Copiar el Base ID y ponerlo en AIRTABLE_EDU_BASE_ID.
