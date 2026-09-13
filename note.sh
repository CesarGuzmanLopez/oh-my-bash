#!/bin/bash
# note.sh — guarda una nota y la envía a Telegram + Memos
# Los tokens se cargan desde .env (los carga oh-my-bash.sh).

# Directorio para guardar los archivos de notas
notes_dir="$HOME/.notes"

# Crea el directorio si no existe
mkdir -p "$notes_dir"

# Abre la configuración web
if [[ "$1" == "-f" ]]; then
    xdg-open "https://notes.guzman-lopez.com/setting"
    exit 0
fi

# Nombre de archivo con fecha y hora
filename="$(date +'%Y-%m-%d_%H-%M-%S').txt"
tempfile="$notes_dir/$filename"

# Comprobando si se pasa un mensaje directamente
if [[ -n "$1" ]]; then
    mensaje="$1"
    printf '%s\n' "$mensaje" > "$tempfile"
else
    # Abre nvim para que el usuario escriba el mensaje
    nvim "$tempfile"
    mensaje=$(cat "$tempfile")
fi

# Si el archivo está vacío, no hacer nada
if [[ ! -s "$tempfile" ]]; then
    echo "No se escribió ningún mensaje. No se enviará nada."
    exit 0
fi

# Función para verificar la conexión a internet y enviar el mensaje
function check_and_send {
    # Ping a google.com para verificar la conexión a internet
    until ping -c 1 google.com > /dev/null 2>&1; do
        echo "No hay conexión a Internet. Reintentando en 2 minutos..."
        sleep 120  # Espera 2 minutos
    done

    # Escapar caracteres especiales en el mensaje (para el JSON de Memos)
    local mensaje_escaped
    mensaje_escaped=$(printf '%s\n' "$mensaje" | sed 's/\\/\\\\/g; s/"/\\"/g' | tr '\n' ' ')

    # Telegram
    if [[ -n "$TOKEN_telegram" && -n "$TOKEN_USER_telegram" ]]; then
        curl -s -X POST "https://api.telegram.org/bot$TOKEN_telegram/sendMessage" \
            -d chat_id="$TOKEN_USER_telegram" -d text="$mensaje" > /dev/null
    else
        echo "Aviso: TOKEN_telegram/TOKEN_USER_telegram vacíos; no se envía a Telegram." >&2
    fi

    # Memos
    if [[ -n "$TOKEN_MEMOS" ]]; then
        curl -s -k -X POST "https://notes.guzman-lopez.com/api/v2/memos" \
            -H "Accept: application/json" \
            -H "Authorization: Bearer $TOKEN_MEMOS" \
            -H "Content-Type: application/json" \
            -d "{\"content\": \"$mensaje_escaped\"}" > /dev/null
    else
        echo "Aviso: TOKEN_MEMOS vacío; no se envía a Memos." >&2
    fi

    echo "Mensaje enviado exitosamente."
}

# Enviar en segundo plano para no bloquear el prompt
check_and_send > /dev/null 2>&1 &
