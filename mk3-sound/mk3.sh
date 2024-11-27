#!/bin/bash
SOUND="/proc/asound/card0/pcm0p/sub0/status"
VOLUME_CONTROL="Master"

initial_volume=0
final_volume=100
duration=5
isSound=false
soundUpPid=0

echo "L" #> $DEVICE
amixer sset "$VOLUME_CONTROL" $initial_volume% >/dev/null 2>&1

# Función de easing (ejemplo: easing cuadrático)
easing() {
  local t=$1   # tiempo actual
  local b=$2   # volumen inicial
  local c=$3   # cambio de volumen (final - inicial)
  local d=$4   # duración

  # Easing cuadrático: t/d * t
  # echo $(bc -l <<< "$b + $c * (($t / $d) * ($t / $d))")
  # Easing sinusoidal: 1 - cos(t / d * (pi / 2))
  echo $(bc -l <<< "$b + $c * (1 - c(3.14159 * $t / (2 * $d)))")
}

# Función para subir el volumen con easing
soundUp() {
  start_time=$(date +%s)

  while true; do
    current_time=$(($(date +%s) - $start_time))

    # Verificamos si hemos alcanzado la duración deseada
    if [ $current_time -ge $duration ]; then
      # Establecemos el volumen final
      amixer sset "$VOLUME_CONTROL" $final_volume% >/dev/null 2>&1
      break
    fi

    # Calculamos el volumen con la función de easing
    eased_volume=$(easing $current_time $initial_volume $(($final_volume - $initial_volume)) $duration)

    # Establecemos el volumen con amixer (eliminamos decimales)
    amixer sset "$VOLUME_CONTROL" ${eased_volume%\.*}% >/dev/null 2>&1

    # Esperamos un poco antes de la siguiente actualización
    sleep 0.1
  done
}

# Monitorea cambios en el archivo especificado
inotifywait -m -e close "$SOUND" |
while read path action file; do
  status=$(cat "$SOUND")

  if [[ "$status" == "closed" ]]; then
    if [ "$isSound" == true ]; then
      if [ $soundUpPid -gt 0 ]; then
        kill $soundUpPid
        wait $soundUpPid 2>/dev/null  # Espera a que el proceso termine de matarse
        soundUpPid=0
      else
        final_volume=$(amixer get Master | grep -oP '\d+(?=%)' | head -n 1)
      fi
      
      #echo "L" > $DEVICE
      echo "L"
      amixer sset "$VOLUME_CONTROL" $initial_volume% >/dev/null 2>&1
      isSound=false
    fi
  else
    if [ "$isSound" == false ]; then
      isSound=true
      echo "H" > $DEVICE
      soundUp &
      soundUpPid=$!
    fi
  fi
done
