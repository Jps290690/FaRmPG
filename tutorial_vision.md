# Tutorial: opencode-vision (MCP de visión para modelos de texto)

> **Para qué sirve:** agrega capacidades de visión a cualquier modelo de texto-only en opencode (Gemma, DeepSeek, Qwen-Coder, etc.). El modelo no ve los píxeles; el MCP analiza la imagen (OCR + descripción vía Google Gemini) y devuelve texto que el modelo sí procesa.
>
> **Cómo usar este archivo:** entregá este tutorial a tu agente de IA (opencode, Claude, etc.) y decile que lo siga paso a paso. Está validado en **Windows 11 + Python 3.14 + opencode 1.18.15** — en macOS/Linux adaptá solo las rutas.

---

## 1. Qué se instala

| Componente | Rol |
|---|---|
| `opencode-vision` (PyPI) | MCP server en Python |
| `pillow` | Metadata de imagen + auto-resize |
| API key de Google (Gemini) | Fallback de visión (free tier, 1500 req/día) |
| `paddleocr` + `paddlepaddle` | OCR local **opcional** (no disponible en Python 3.14) |

**Costo: $0** con el free tier de Gemini (sin tarjeta de crédito).

---

## 2. Instalación

```bash
pip install opencode-vision
```

- `opencode-vision` — instalación mínima (solo Gemini).
- `opencode-vision[paddle]` — agrega PaddleOCR local. **Solo en Python ≤ 3.13**: para Python 3.14 no existe `paddlepaddle` (ver paso 5).

**Averiguar la ruta absoluta de Python** (la vas a necesitar en los pasos 4 y 6 — cada PC tiene una distinta):

```bash
py -c "import sys; print(sys.executable)"
# ej. C:\Users\<tu_usuario>\AppData\Local\Programs\Python\Python312\python.exe
```

Verificar instalación:

```bash
py -m pip show opencode-vision
py -c "import opencode_vision.server; print('server OK')"
```

---

## 3. API key de Gemini (gratis)

1. Ir a https://aistudio.google.com/apikey → "Create API key".
2. Guardarla en el archivo `.env` de la config global de opencode:

```bash
# Windows: C:\Users\<TU_USUARIO>\.config\opencode\.env
# macOS/Linux: ~/.config/opencode/.env
```

```bash
GOOGLE_API_KEY=pega_tu_key_acá
```

El server detecta la key en este orden: env var `GOOGLE_API_KEY` → `GOOGLE_GENERATIVE_AI_API_KEY` → `~/.config/opencode/.env` → `~/.env` → `$PWD/.env`.

**Atención:** `gemini-2.5-flash` ya NO existe para cuentas nuevas (404). El paso 5 corrige el modelo a `gemini-3.1-flash-lite`.

---

## 4. Configurar el MCP en opencode

Editar el config global de opencode (`opencode.json`, `opencode.jsonc` o `~/.config/opencode/opencode.json*`):

```json
{
  "$schema": "https://opencode.ai/config.json",
  "mcp": {
    "vision": {
      "type": "local",
      "command": ["cmd", "/c", "<RUTA_DE_PYTHON>", "-m", "opencode_vision.server"],
      "enabled": true,
      "timeout": 30000,
      "environment": {
        "PYTHONIOENCODING": "utf-8",
        "PYTHONPATH": "C:\\Users\\<tu_usuario>\\opencode-vision"
      }
    }
  }
}
```

Notas:
- **Windows:** usar `cmd /c` + la ruta **absoluta** de Python que obtuviste en el paso 2 (opencode puede no heredar el PATH; no uses `~` ni `python` a secas). Ejemplo real: `"command": ["cmd", "/c", "C:\\Users\\nacho\\AppData\\Local\\Programs\\Python\\Python312\\python.exe", "-m", "opencode_vision.server"]`. En macOS/Linux: `["python3", "-m", "opencode_vision.server"]`.
- `PYTHONIOENCODING=utf-8` evita errores de codificación cp1252 en los logs.
- **`PYTHONPATH`** apunta a la carpeta con el paquete **parcheado** del paso 5 (`C:\Users\<tu_usuario>\opencode-vision`). Sin esto, opencode cargaría el paquete original de `site-packages` (sin parches).
- Si el MCP queda "failed", ver diagnóstico en el paso 6.

---

## 5. PARCHES OBLIGATORIOS (Windows + opencode)

`opencode-vision 2.1.0` no funciona out-of-the-box con opencode en Windows. Hay que aplicar 5 parches sobre 4 archivos (`server.py` lleva 2).

> **Si tu versión de `pip show opencode-vision` no es 2.1.0 exacta:** compará el código original antes de aplicar cada parche (un diff difiere según la versión). Los bloques "Antes:" de abajo son los de 2.1.0. Los bloques nuevos (Después:) son compatibles con 2.x.

**Enfoque:** NO parchear el paquete de `site-packages` (está protegido por permisos de usuario y cualquier `pip install --upgrade` revierte los cambios). En su lugar, **copiar el paquete a una carpeta propia del usuario** y parchear ahí. El `PYTHONPATH` del paso 4 ya apunta a esa copia.

**1) Copiar el paquete instalado** (localizarlo primero — cada instalación tiene su propio `site-packages`):

```bash
py -c "import opencode_vision.server as s; print(s.__file__)"
# → C:\<ruta>\Lib\site-packages\opencode_vision\...
```

```bash
# Windows:
xcopy /E /I /Y "C:\<ruta>\Lib\site-packages\opencode_vision" "C:\Users\<tu_usuario>\opencode-vision\opencode_vision"
```

Verificar que la copia sea la que usa Python (debe resolver al directorio propio, no a site-packages):

```bash
py -c "import sys; sys.path.insert(0, r'C:\Users\<tu_usuario>\opencode-vision'); import opencode_vision.server as s; print(s.__file__)"
# → C:\Users\<tu_usuario>\opencode-vision\opencode_vision\server.py
```

**2) Aplicar los 5 parches (5.1 a 5.5) sobre los archivos de la copia `C:\Users\<tu_usuario>\opencode-vision\opencode_vision\`.**

**Importante:** los parches se aplican una sola vez por máquina y **sobreviven** reinstalaciones del paquete (porque la copia es tuya). Si borrás la carpeta `opencode-vision`, hay que repetir el paso 5.

### 5.1 `mcp.py` — JSON plano por línea (bug crítico en Windows)

**Síntoma:** `Operation timed out after 30000ms`. opencode en Windows habla **JSON delimitado por nueva línea** (sin framing `Content-Length`). El paquete solo entiende `Content-Length`.

Reemplazar las funciones `send` y `recv` y agregar el flag `_plain_json`. En `mcp.py`, el código **original** (a localizar):

```python
log = logging.getLogger(__name__)


def send(msg: dict) -> None:
    """Send a JSON-RPC message with MCP Content-Length framing.

    ⚠️ Content-Length MUST be the number of BYTES in the body (UTF-8 encoded),
    not the number of characters — emoji and non-ASCII characters use
    multiple bytes.
    """
    try:
        body = json.dumps(msg, ensure_ascii=False, default=str).encode("utf-8")
        header = f"Content-Length: {len(body)}\r\n\r\n"
        sys.stdout.buffer.write(header.encode("utf-8") + body)
        sys.stdout.buffer.flush()
    except Exception as e:
        log.error("mcp.send failed: %s", e)


def recv() -> dict | None:
    """Receive a JSON-RPC message from stdin with MCP framing."""
    try:
        content_length = 0
        while True:
            line = sys.stdin.buffer.readline()
            if not line:
                return None
            line = line.strip()
            if not line:
                break
            decoded = line.decode("utf-8", errors="replace")
            if decoded.lower().startswith("content-length:"):
                content_length = int(decoded.split(":", 1)[1].strip())

        if content_length > 0:
            body = sys.stdin.buffer.read(content_length)
            return json.loads(body.decode("utf-8"))
        return None
    except json.JSONDecodeError:
        return None
    except Exception as e:
        log.error("mcp.recv error: %s", e)
        return None
```

Reemplazarlo completo por (el flag `_plain_json` se inserta **justo después de la línea `log = logging.getLogger(__name__)`**):

```python
log = logging.getLogger(__name__)

_plain_json = False


def send(msg: dict) -> None:
    """Send a JSON-RPC message.
    Uses MCP Content-Length framing by default, or plain newline-delimited
    JSON when the client was detected speaking that format (see recv()).
    """
    try:
        body = json.dumps(msg, ensure_ascii=False, default=str).encode("utf-8")
        if _plain_json:
            sys.stdout.buffer.write(body + b"\n")
        else:
            header = f"Content-Length: {len(body)}\r\n\r\n"
            sys.stdout.buffer.write(header.encode("utf-8") + body)
        sys.stdout.buffer.flush()
    except Exception as e:
        log.error("mcp.send failed: %s", e)


def recv() -> dict | None:
    """Receive a JSON-RPC message from stdin.
    Accepts both the standard MCP Content-Length framing and plain
    newline-delimited JSON. The detected format is stored so send() can reply in kind.
    """
    global _plain_json
    try:
        content_length = 0
        while True:
            line = sys.stdin.buffer.readline()
            if not line:
                return None
            line = line.strip()
            if not line:
                break
            decoded = line.decode("utf-8", errors="replace")
            if decoded.lower().startswith("content-length:"):
                content_length = int(decoded.split(":", 1)[1].strip())
            elif decoded.startswith("{"):
                _plain_json = True
                return json.loads(decoded)

        if content_length > 0:
            body = sys.stdin.buffer.read(content_length)
            return json.loads(body.decode("utf-8"))
        return None
    except json.JSONDecodeError:
        return None
    except Exception as e:
        log.error("mcp.recv error: %s", e)
        return None
```

### 5.2 `server.py` — protocolVersion

**Síntoma:** `Server's protocol version is not supported: 0.1.0`.

En `server.py`, la función `handle_initialize` **original** (a localizar):

```python
def handle_initialize(msg):
    return mcp.result(msg["id"], {
        "protocolVersion": "0.1.0",
        "serverInfo": {"name": "opencode-vision-server", "version": "2.0.0"},
        "capabilities": {"tools": {}},
    })
```

Reemplazarla por (devuelve la versión de protocolo que pidió el cliente):

```python
def handle_initialize(msg):
    params = msg.get("params", {})
    requested = params.get("protocolVersion", "0.1.0")
    return mcp.result(msg["id"], {
        "protocolVersion": requested,
        "serverInfo": {"name": "opencode-vision-server", "version": "2.0.0"},
        "capabilities": {"tools": {}},
    })
```

### 5.3 `gemini.py` — modelo deprecado

**Síntoma:** `HTTP 404: This model models/gemini-2.5-flash is no longer available to new users.`

En `gemini.py`, el bloque de constantes **original** (a localizar):

```python
GEMINI_MODEL = "gemini-2.5-flash"
GEMINI_URL = (
    f"https://generativelanguage.googleapis.com/v1beta/models/"
    f"{GEMINI_MODEL}:generateContent"
)
```

Reemplazarlo por:

```python
GEMINI_MODEL = os.environ.get("GEMINI_MODEL", "gemini-3.1-flash-lite")
GEMINI_API_BASE = os.environ.get(
    "GEMINI_API_BASE",
    "https://generativelanguage.googleapis.com/v1beta",
)
```

Y en la función `call`, la línea de la URL **original** (a localizar):

```python
    url = f"{GEMINI_URL}?key={api_key}"
```

Reemplazarla por:

```python
    url = f"{GEMINI_API_BASE}/models/{GEMINI_MODEL}:generateContent?key={api_key}"
```

El modelo se puede cambiar sin tocar código con la env var `GEMINI_MODEL`.

### 5.4 `ocr.py` — PaddleOCR en Python 3.14

**Síntoma:** `PaddleOCR init failed: dependency 'paddlepaddle' is not installed` y ~10s perdidos descargando modelos.

En `ocr.py`, el bloque `try` de import **original** (a localizar):

```python
try:
    from paddleocr import PaddleOCR as _PaddleOCR  # type: ignore[import-untyped]

    HAS_PADDLE = True
except ImportError:
    pass
```

Reemplazarlo por (agregando la exigencia del runtime de PaddlePaddle):

```python
try:
    import paddle  # noqa: F401  (PaddlePaddle runtime; absent for Python 3.14)
    from paddleocr import PaddleOCR as _PaddleOCR  # type: ignore[import-untyped]

    HAS_PADDLE = True
except ImportError:
    pass
```

Así el server usa directo el fallback de Gemini (OCR también funciona, vía Gemini).

### 5.5 `server.py` — leer la imagen del portapapeles de Windows

**Qué agrega:** el tool `vision_clipboard`, para analizar la imagen que está copiada en el portapapeles sin pasar una ruta (ej. `Win+Shift+S`). En `server.py`:

**a) Agregar el tool `vision_clipboard` al final de la lista `TOOLS`.** En `server.py`, buscar el cierre de la lista — el tool `vision_analyze` termina con:

```python
            "required": ["image_path"],
        },
    },
]
```

Insertar el bloque nuevo **entre ese `},\n]`** (después del tool `vision_analyze` y antes del `]` que cierra la lista), dejando:

```python
            "required": ["image_path"],
        },
    },
    {
        "name": "vision_clipboard",
        "description": (
            "Analyze the image currently in the Windows clipboard. Returns "
            "complete analysis (metadata + description + OCR). Use this when "
            "the user has copied/pasted an image (e.g. Win+Shift+S) and no "
            "file path is available. Pass an optional `prompt` for specific "
            "questions about the image."
        ),
        "inputSchema": {
            "type": "object",
            "properties": {
                "prompt": {
                    "type": "string",
                    "description": "Optional custom question about the clipboard image",
                },
            },
        },
    },
]
```

**b) Agregar la función `_clipboard_image_path()`.** Insertar el bloque completo **entre el fin de la lista `TOOLS` (`]` en línea propia) y el comentario `# ── MCP Handlers`**:

```python
def _clipboard_image_path() -> tuple[str, str | None]:
    """Grab the image currently in the Windows clipboard. Returns (path, error)."""
    try:
        from PIL import Image, ImageGrab
    except ImportError:
        return "", "Pillow is required for clipboard capture (pip install pillow)"
    try:
        grabbed = ImageGrab.grabclipboard()
    except Exception as e:
        return "", f"{type(e).__name__}: {e}"
    if grabbed is None:
        return "", (
            "Clipboard does not contain an image. Copy an image first "
            "(e.g. Win+Shift+S) and try again."
        )
    if isinstance(grabbed, list):
        for candidate in grabbed:
            p = Path(candidate)
            if p.is_file() and p.suffix.lower() in {".png", ".jpg", ".jpeg", ".gif", ".bmp", ".webp"}:
                return str(p), None
        return "", "Clipboard file list contains no supported image file."
    if not isinstance(grabbed, Image.Image):
        return "", f"Unsupported clipboard content type: {type(grabbed).__name__}."

    out_path = LOG_DIR / "clipboard.png"
    try:
        grabbed.convert("RGB").save(str(out_path), "PNG")
    except Exception as e:
        return "", f"Could not save clipboard image: {e}"
    return str(out_path), None
```

**c) En `handle_call_tool`, ramificar antes del chequeo de `image_path`:** insertar este bloque completo **justo después de la línea `args = params.get("arguments", {})` y antes de la línea `image_path = args.get("image_path", "")`**:

```python
    if name == "vision_clipboard":
        clip_path, clip_err = _clipboard_image_path()
        if clip_err:
            return mcp.error(msg["id"], -32000, clip_err)
        try:
            prompt = args.get("prompt")
            if prompt:
                result = ocr.describe_image(clip_path, prompt)
            else:
                result = ocr.full_analysis(clip_path)
            if "error" in result:
                return mcp.error(msg["id"], -32000, result["error"])
            return mcp.result(msg["id"], {
                "content": [{"type": "text", "text": result.get("text", str(result))}],
            })
        except Exception as e:
            log.error("Tool crash: %s\n%s", e, traceback.format_exc())
            return mcp.error(msg["id"], -32000, f"{type(e).__name__}: {e}")

    image_path = args.get("image_path", "")
```

Al final, `handle_call_tool` debe quedar así:

```python
def handle_call_tool(msg):
    params = msg.get("params", {})
    name = params.get("name", "")
    args = params.get("arguments", {})

    if name == "vision_clipboard":
        ...  # (bloque insertado arriba)

    image_path = args.get("image_path", "")
    if not image_path:
        return mcp.error(msg["id"], -32000, "Missing required: image_path")

    path_obj, err = _resolve_path(image_path)
    if err:
        return mcp.error(msg["id"], -32000, err)
    ...
```

La imagen capturada se guarda temporalmente como `~/.local/share/opencode-vision/clipboard.png` (se sobrescribe en cada llamada).

### 5.6 Verificación de los parches (sintaxis + import)

Con `PYTHONPATH` apuntando a la copia (mismo valor que el paso 4), confirmar que nada queda con errores antes de reiniciar opencode:

```bash
# Windows PowerShell:
$env:PYTHONPATH = "C:\Users\<tu_usuario>\opencode-vision"
<RUTA_DE_PYTHON> -m py_compile "C:\Users\<tu_usuario>\opencode-vision\opencode_vision\mcp.py" "C:\Users\<tu_usuario>\opencode-vision\opencode_vision\server.py" "C:\Users\<tu_usuario>\opencode-vision\opencode_vision\gemini.py" "C:\Users\<tu_usuario>\opencode-vision\opencode_vision\ocr.py"
# sin errores = OK
```

Luego verificar el import y los tools cargados:

```bash
$env:PYTHONPATH = "C:\Users\<tu_usuario>\opencode-vision"
py -c "import opencode_vision.server as s; print([t['name'] for t in s.TOOLS])"
# Los 4 tools deben aparecer: ['vision_describe', 'vision_ocr', 'vision_analyze', 'vision_clipboard']
```

Si aparece `UnicodeEncodeError` en `py -m py_compile`, no es un error del parche: es la consola en cp1252; hacer el test de handshake del paso 6 que usa `PYTHONIOENCODING=utf-8`.

---

## 6. Verificación

```bash
opencode mcp list
#  ✓ vision connected
```

Si figura `✗ failed`, revisar:
1. Que los 5 parches del paso 5 estén aplicados en `C:\Users\<tu_usuario>\opencode-vision\opencode_vision\` (el log del server está en `~/.local/share/opencode-vision/vision-server.log`).
2. Que la key exista en el `.env` correcto.
3. Que `PYTHONPATH` del paso 4 apunte a la copia parcheada.
4. Test de handshake manual (debe responder en <1s):

```bash
# Windows PowerShell (reemplazá <RUTA_DE_PYTHON> y <PYTHONPATH> con los de los pasos 2 y 4):
$lines = @('{"method":"initialize","params":{"protocolVersion":"2025-11-25"},"jsonrpc":"2.0","id":0}')
$input = ($lines -join "`n") + "`n"
$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = "<RUTA_DE_PYTHON>"
$psi.Arguments = "-m opencode_vision.server"
$psi.EnvironmentVariables["PYTHONPATH"] = "<PYTHONPATH>"
$psi.RedirectStandardInput = $true
$psi.RedirectStandardOutput = $true
$psi.UseShellExecute = $false
$p = [System.Diagnostics.Process]::Start($psi)
$p.StandardInput.Write($input); $p.StandardInput.Close()
$p.StandardOutput.ReadToEnd()
# Debe devolver: {"jsonrpc":"2.0","id":0,"result":{"protocolVersion":"2025-11-25",...}}
```

**Reiniciar opencode** después de tocar config o parches (la config se carga al arranque).

---

## 7. Uso en el chat

El modelo de texto **no ve imágenes pegadas** (las pega en el clipboard y opencode no las persiste). Dos formas de analizar una imagen:

**a) Con ruta de archivo:**

```
Analizá la imagen C:\Users\<tu_usuario>\Screenshot_2026_08_08_143435.jpg
¿Qué texto hay en C:\Users\<tu_usuario>\Desktop\captura.png?
```

**b) Directo desde el portapapeles** (sin dar ruta — copiá la imagen con `Win+Shift+S` y pedí):

```
Analizá la captura que acabo de copiar
```

El modelo invoca `vision_clipboard` automáticamente. Si no lo hace, pedírselo explícito: "usá la tool de portapapeles".

Tools disponibles:

| Tool | Función |
|---|---|
| `vision_describe(path, prompt?)` | Describe la imagen (composición, colores, texto visible, contexto) |
| `vision_ocr(path)` | Extrae todo el texto de la imagen |
| `vision_analyze(path)` | Metadata + descripción + OCR completo |
| `vision_clipboard(prompt?)` | Lo mismo que `vision_analyze`, pero lee la imagen del portapapeles de Windows (sin ruta) |

El modelo las invoca automáticamente si ve un path de imagen en el prompt. Si no, pedirle explícitamente: "usá la tool de visión".

---

## Referencias

- Repo: https://github.com/NickRivers1983/opencode-vision
- PyPI: https://pypi.org/project/opencode-vision
- Bugs de opencode en Windows: anomalyco/opencode#22310, #6994, #25904 (el fix `cmd /c` y el framing JSON plano son los workarounds usados aquí)
