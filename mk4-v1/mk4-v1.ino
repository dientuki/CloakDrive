const int SENSOR_PIN = 8; // Pin donde está conectado el sensor
const int RELAY_PIN = 4; //LED_BUILTIN for test

bool ledState = LOW;
bool presenceDetected = LOW;
char command;
int currentState;

unsigned long lastReportTime = 0;
unsigned long currentMillis = 0;

void setup() {
  Serial.begin(9600);  // Inicia la comunicación serie
  pinMode(RELAY_PIN, OUTPUT); // Configura el pin del LED como salida
  pinMode(LED_BUILTIN, OUTPUT);
  pinMode(SENSOR_PIN, INPUT); // Configurar el pin 8 como entrada
  digitalWrite(RELAY_PIN, HIGH);
  digitalWrite(LED_BUILTIN, LOW);
  //Relay Low = energizado = NA
}

void processSerialInput() {
  if (Serial.available() > 0) {           // Revisa si hay datos disponibles
    command = Serial.read();
    
    if (command == 'H') {
      ledState = LOW;  
    } else if (command == 'L') {
      ledState = HIGH;
    }
    digitalWrite(RELAY_PIN, ledState);
  }
}

void processScreen() {
  currentState = digitalRead(SENSOR_PIN); // Leer el estado del pin
  currentMillis = millis(); // Obtener el tiempo actual desde el inicio

  if (presenceDetected == LOW) {
    presenceDetected = currentState;
  }
  
  if (currentMillis - lastReportTime >= 2000) {
    if (presenceDetected == HIGH) {
      Serial.println(1);  // Enviar "HIGH" si el sensor está en HIGH
    }
    presenceDetected = LOW;
    lastReportTime = currentMillis;  // Actualizar el tiempo del último reporte
  }  
}

void loop() {
  processSerialInput(); 
  processScreen();
}