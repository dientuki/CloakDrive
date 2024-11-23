bool ledState = LOW; 
char command; 

void setup() {
  Serial.begin(9600);  // Inicia la comunicación serie
  pinMode(LED_BUILTIN, OUTPUT); // Configura el pin del LED como salida
  digitalWrite(LED_BUILTIN, LOW);
}

void processSerialInput() {
  if (Serial.available() > 0) {           // Revisa si hay datos disponibles
    command = Serial.read();              // Lee un carácter del puerto serie
    
    if (command == 'H') {
      ledState = HIGH;                    // Actualiza el estado del LED
    } else if (command == 'L') {
      ledState = LOW;                     // Actualiza el estado del LED
    }
    digitalWrite(LED_BUILTIN, ledState);  // Aplica el estado al LED
  }
}

void loop() {
  
  processSerialInput(); 
}