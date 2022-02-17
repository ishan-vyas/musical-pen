// Include teh Newping library for the ultrasonic sensor
#include <NewPing.h>
// Include the Wire library for the accelerometer
#include <Wire.h>

// Intialize starting variables
int ADXL345 = 0x53;

NewPing sonarX(12,13, 30);
NewPing sonarY(10,11, 30);

int fsrPin = 0;    
int soundPin = 1;
int soundReading;

unsigned long previousMillis = 0;
const long interval = 2;
int currentSonarX=0;
int currentSonarY=0;
int currentPressure=0;
int currentSound=0;
int currentAngle=0;

float X_out, Y_out, Z_out;

// Setup
void setup() {
  // put your setup code here, to run once:

  Serial.begin(9600);

  // Begin transmission between the accelerometer and the arduino
  Wire.begin();
  Wire.beginTransmission(ADXL345);
  Wire.write(0x2D);
  Wire.write(8);
  Wire.endTransmission();
}

// Loop
void loop() {

  // Transmission loop
  Wire.beginTransmission(ADXL345);
  Wire.write(0x32);
  Wire.endTransmission(false);
  Wire.requestFrom(ADXL345,6,true);
  
  unsigned long currentMillis = millis();
  if(currentMillis - previousMillis >= interval){
      previousMillis = currentMillis;

      // Read the different distances for the ultrasonic sensor
      currentSonarX = sonarX.ping_cm();
      currentSonarY = sonarY.ping_cm();

      // Read the pressure reading
      currentPressure = analogRead(fsrPin); 

      // Convert sound reading to something more readable
      soundReading = analogRead(soundPin);
      if(soundReading < 512){
        currentSound = 512 - soundReading;
      }else{
        currentSound = soundReading - 512;  
      }

      // Read the orientation of the pen
      X_out = (Wire.read() | Wire.read() << 8);
      X_out = X_out/256;

      Y_out = (Wire.read() | Wire.read() << 8);
      Y_out = Y_out/256;

      Z_out = (Wire.read() | Wire.read() << 8);
      Z_out = Z_out/256;

      // Compute the angle using the X reading
      currentAngle = X_out * 100;

      // Print these readings to the serial port for supercollider to read from
      // Use different characters to split between different sensor readings.
      Serial.print(currentSonarX);
      Serial.print("x");

      // Serial.print(" ");
      
      Serial.print(currentSonarY);
      Serial.print("y");

      // Serial.print(" ");
      
      Serial.print(currentPressure);
      Serial.print("p");

      // Serial.print(" ");
      
      Serial.print(currentSound);
      Serial.print("s");

      // Serial.print(" ");

      Serial.print(currentAngle);
      Serial.print("a");
    } 
    
}
