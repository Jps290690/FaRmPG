# Godot MCP

Este proyecto usa [godot-mcp](https://github.com/yanhuifair/Godot-MCP) (`@yanhuifair/godot-mcp`) para que un agente de IA controle el editor y el juego de Godot de forma autónoma.

## Requisitos

- Godot 4.x (instalado en `F:\Godot_v4.6-stable\Godot_v4.6-stable_win64.exe`)
- Node.js 18+ (probado con v24)

## Instalación

### 1. Plugin del editor

El plugin ya está instalado en `addons/godot-mcp/` y habilitado en `project.godot`. Para reinstalarlo o actualizarlo:

```powershell
npx -y @yanhuifair/godot-mcp@latest --enable-plugin -p .
```

Si Godot está abierto, reiniciar el proyecto (Project → Reload Current Project) para que tome el plugin.

### 2. Configuración MCP (opencode)

El server está registrado en `opencode.json`:

```json
{
  "mcp": {
    "godot-mcp": {
      "type": "local",
      "command": ["npx", "-y", "@yanhuifair/godot-mcp", "-p", "."],
      "enabled": true,
      "environment": {
        "GODOT_PATH": "F:\\Godot_v4.6-stable\\Godot_v4.6-stable_win64.exe"
      }
    }
  }
}
```

Reiniciar opencode para que cargue la config.

## Verificación

1. Abrir el proyecto en Godot y confirmar en el output: `[Godot MCP] Plugin v… loaded — TCP on 127.0.0.1:9876`.
2. En opencode, pedir al agente que ejecute `get_status`; debe devolver el conteo de tools (386) y el estado de las conexiones.
3. Probar comandos como: "List all scenes in the project", "Run the game and take a screenshot".

## Notas

- El server tiene 386 tools; si el agente no sabe cuál usar, pedirle que use `search_tools`.
- Cada edición de escena que haga la IA se puede deshacer con **Ctrl+Z** en Godot.
- Las herramientas que escriben archivos crean copias de respaldo `.bak`.
- Para modo de solo lectura: `npx -y @yanhuifair/godot-mcp -p . --read-only`.
