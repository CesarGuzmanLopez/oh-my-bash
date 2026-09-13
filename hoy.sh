#!/bin/bash

# Configuración por defecto
HOURS=12
STEP=1
SHOW_TEMPERATURE=true
SHOW_CLOUDS=false
SHOW_RAIN=false
SHOW_WIND=false
SHOW_PRESSURE=false
SHOW_VISIBILITY=false

# ── Dependencias ──
for _dep in curl jq; do
    command -v "$_dep" > /dev/null 2>&1 || { echo "hoy: falta '$_dep'." >&2; exit 1; }
done

# ── Clave del clima (defínela en .env como WEATHERAPI_KEY) ──
weather_key=${WEATHERAPI_KEY:-${API_WHWATHERAPI_KEY:-}}
if [[ -z $weather_key ]]; then
    echo "hoy: falta WEATHERAPI_KEY (defínela en ~/oh-my-bash-fork/.env)." >&2
    exit 1
fi

# ── Caché de respuestas de API (10 min por defecto) ──
HOY_CACHE_TTL=${HOY_CACHE_TTL:-600}
_hoy_cache_dir=${XDG_CACHE_HOME:-$HOME/.cache}/hoy
mkdir -p "$_hoy_cache_dir"
_hoy_mtime() {
    case $(uname) in
        Darwin) stat -f '%m' "$1" 2> /dev/null ;;
        *) stat -c '%Y' "$1" 2> /dev/null ;;
    esac
}
_hoy_fetch() { # nombre url
    local f="$_hoy_cache_dir/$1.json" now data m
    now=$(date +%s)
    if [[ -s $f ]]; then
        m=$(_hoy_mtime "$f")
        if [[ -n $m ]] && (( now - m < HOY_CACHE_TTL )); then
            cat "$f"
            return
        fi
    fi
    data=$(curl -s --max-time 10 "$2")
    [[ -n $data ]] && printf '%s' "$data" > "$f"
    printf '%s' "$data"
}

# Función para obtener emojis
get_emoji() {
    local value=$1
    local emoji

    case $2 in
        temp)
            if(( $(echo "$value > 35" | bc -l) )); then emoji="☠️ "
            elif(( $(echo "$value > 30" | bc -l) )); then emoji="🔥"
            elif (( $(echo "$value > 25" | bc -l) )); then emoji="🥵"
            elif (( $(echo "$value < 10" | bc -l) )); then emoji="❄️"
            elif(( $(echo "$value < 5" | bc -l) )); then emoji="🥶"
            else emoji="🌞"; fi
            ;;
        rain)
            if [ -n "$value" ] && (( $(echo "$value > 50" | bc -l) )); then emoji="🌧️"
            else emoji="☀️"; fi
            ;;
        cloud)
            if [ -n "$value" ] && (( $(echo "$value > 50" | bc -l) )); then emoji="☁️"
            elif [ -n "$value" ] && (( $(echo "$value > 25" | bc -l) )); then emoji="⛅"
            else emoji="☀️"; fi
            ;;
        is_day)
            local hour
            hour=$(date -d "$value" "+%H")
            if [ "$hour" -ge 6 ] && [ "$hour" -lt 18 ]; then emoji="🌞"
            else emoji="🌙"; fi
            ;;
        wind)
            if [ -n "$value" ] && (( $(echo "$value > 30" | bc -l) )); then emoji="🌬️"
            elif [ -n "$value" ] && (( $(echo "$value > 10" | bc -l) )); then emoji="💨"
            else emoji="🍃"; fi
            ;;
        pressure)
            if [ -n "$value" ] && (( $(echo "$value > 1013" | bc -l) )); then emoji="🌡️"
            elif [ -n "$value" ] && (( $(echo "$value < 1000" | bc -l) )); then emoji="❗"
            else emoji="✔️"; fi
            ;;
        visibility)
            if [ -n "$value" ] && (( $(echo "$value < 5" | bc -l) )); then emoji="🌫️"
            elif [ -n "$value" ] && (( $(echo "$value < 10" | bc -l) )); then emoji="🌁"
            else emoji="👀"; fi
            ;;
    esac

    echo "$emoji"
}

# Procesar los parámetros de línea de comandos
while getopts "h:s:tcrawpv" opt; do
    case ${opt} in
        h ) HOURS=$OPTARG ;;
        s ) STEP=$OPTARG ;;
        t ) SHOW_TEMPERATURE=true ;;
        c ) SHOW_CLOUDS=true ;;
        r ) SHOW_RAIN=true ;;
        w ) SHOW_WIND=true ;;
        p ) SHOW_PRESSURE=true ;;
        v ) SHOW_VISIBILITY=true ;;
        a ) SHOW_TEMPERATURE=true; SHOW_CLOUDS=true; SHOW_RAIN=true; SHOW_WIND=true; SHOW_PRESSURE=true; SHOW_VISIBILITY=true ;;
        \?|: ) echo "Uso: $0 [-h horas] [-s paso] [-c {nubes}] [-r {lluvia}] [-t {temperatura}] [-w {viento}] [-p {presión}] [-v {visibilidad}] [-a {todos}]"; exit 1 ;;
    esac
done

# URL de ipinfo.io para obtener información geográfica basada en la IP actual
API_URL="https://ipinfo.io/json"

# Realiza la solicitud a ipinfo.io (con caché)
response=$(_hoy_fetch ipinfo "$API_URL")

# Extrae la latitud y longitud de la respuesta JSON
latitude=$(echo "$response" | jq -r '.loc | split(",")[0]')
longitude=$(echo "$response" | jq -r '.loc | split(",")[1]')

# Define la URL de la API
API_URL="https://api.weatherapi.com/v1/forecast.json?key=${weather_key}&q=${latitude},${longitude}&days=3&aqi=no&alerts=no"

# Realiza la solicitud a la API (con caché)
response=$(_hoy_fetch weather "$API_URL")

# Imprime las condiciones para las próximas horas según los parámetros
echo "Condiciones para las próximas $HOURS horas con un paso de $STEP horas:"

# Construir la cabecera de la tabla
table_header="Hora"
if [ "$SHOW_TEMPERATURE" = true ]; then table_header+="|Temperatura (°C)"; fi
if [ "$SHOW_CLOUDS" = true ]; then table_header+="|Nubosidad (%)"; fi
if [ "$SHOW_RAIN" = true ]; then table_header+="|Lluvia (%)"; fi
if [ "$SHOW_WIND" = true ]; then table_header+="|Viento (km/h)"; fi
if [ "$SHOW_PRESSURE" = true ]; then table_header+="|Presión (hPa)"; fi
if [ "$SHOW_VISIBILITY" = true ]; then table_header+="|Visibilidad (km)"; fi
#la hora de inicio es esta hora menos una hora y quito el 0 ubucuak si ki hay 0
start_hour=$(date +"%H" | sed 's/^0//')
# Construir la línea de separación de la tabla
table_separator=$(echo "$table_header" | sed 's/./-/g')

# Imprime la cabecera de la tabla
echo "$table_header" | column -t -s '|'
echo "$table_separator"

# Imprime los datos para cada hora según los comandos aceptados
for ((hour = $start_hour; hour < $start_hour+$HOURS; hour+=$STEP)); do
    hour_data=""
    to_day=$(($hour/24))
    hour_time=$(echo "$response" | jq -r ".forecast.forecastday[$to_day].hour[$hour%24].time")
    time=$(date -d "$hour_time" "+%H:%M")
    hour_data+="$hour_time $(get_emoji "$time" "is_day")"
    if [ "$SHOW_TEMPERATURE" = true ]; then
        hour_temp=$(echo "$response" | jq -r ".forecast.forecastday[$to_day].hour[$hour%24].temp_c")
        hour_data+="|$(printf "%5s" "$hour_temp")°C $(get_emoji "$hour_temp" "temp")"
    fi

    if [ "$SHOW_CLOUDS" = true ]; then
        hour_cloud=$(echo "$response" | jq -r ".forecast.forecastday[$to_day].hour[$hour%24].cloud")
        hour_data+="|$(printf "%5s" "$hour_cloud")% $(get_emoji "$hour_cloud" "cloud")"
    fi

    if [ "$SHOW_RAIN" = true ]; then
        hour_rain=$(echo "$response" | jq -r ".forecast.forecastday[$to_day].hour[$hour%24].chance_of_rain")
        hour_data+="|$(printf "%5s" "$hour_rain")% $(get_emoji "$hour_rain" "rain")"
    fi

    if [ "$SHOW_WIND" = true ]; then
        hour_wind=$(echo "$response" | jq -r ".forecast.forecastday[$to_day].hour[$hour%24].wind_kph")
        hour_data+="|$(printf "%5s" "$hour_wind") km/h $(get_emoji "$hour_wind" "wind")"
    fi

    if [ "$SHOW_PRESSURE" = true ]; then
        hour_pressure=$(echo "$response" | jq -r ".forecast.forecastday[$to_day].hour[$hour%24].pressure_mb")
        hour_data+="|$(printf "%5s" "$hour_pressure") hPa $(get_emoji "$hour_pressure" "pressure")"
    fi

    if [ "$SHOW_VISIBILITY" = true ]; then
        hour_visibility=$(echo "$response" | jq -r ".forecast.forecastday[$to_day].hour[$hour%24].vis_km")
        hour_data+="|$(printf "%5s" "$hour_visibility") km $(get_emoji "$hour_visibility" "visibility")"
    fi

    echo "$hour_data" | column -t -s '|'
done

