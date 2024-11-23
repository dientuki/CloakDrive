#!/bin/bash

DEVICE="/dev/ttyACM0"  # Cambia esto si tu puerto es diferente
BAUD=9600

# Configurar el puerto serie
stty -F $DEVICE $BAUD cs8 -cstopb -parenb -hupcl

# Función para enviar comandos al puerto serie
send_command() {
    local command=$1
    echo -n "$command" > $DEVICE
}

# Loop infinito para alternar el estado del LED
while true; do
    send_command "H"  # Enciende el LED
    sleep 2           # Espera 2 segundos
    send_command "L"  # Apaga el LED
    sleep 2           # Espera 2 segundos
done
