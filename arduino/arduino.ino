#include <Wire.h>
#include <MPU6050.h>
#include <TinyGPS++.h>
#include <SoftwareSerial.h>

MPU6050 mpu;
TinyGPSPlus gps;
SoftwareSerial gpsSerial(4, 5); // RX, TX

int impactPin = 7;
int ledPin = 13;

int confirmCount = 0;
int confirmThreshold = 3;

float data[5];
bool impactSent = false;

// Thresholds
float lowThreshold = 1;
float mediumThreshold = 2;
float highThreshold = 3;

float filteredAcc = 0;
String severity = "NONE";

void setup() {
  Serial.begin(9600);
  Wire.begin();

  gpsSerial.begin(9600);

  pinMode(impactPin, INPUT);
  pinMode(ledPin, OUTPUT);

  mpu.initialize();
  delay(1000);

  if (!mpu.testConnection()) {
    Serial.println("MPU6050 connection FAILED");
    while (1);
  } else {
    Serial.println("MPU6050 connected");
  }
}

void loop() {

  // Read GPS
  while (gpsSerial.available()) {
    gps.encode(gpsSerial.read());
  }

  // Impact sensor
  int impact = digitalRead(impactPin);

  if (impact == LOW) {
    confirmCount++;
  } else {
    confirmCount = 0;
    impactSent = false;
  }

  bool impactDetected = (confirmCount >= confirmThreshold);

  // MPU6050
  int16_t ax, ay, az;
  mpu.getAcceleration(&ax, &ay, &az);

  // Convert to G-force
  data[0] = ax / 16384.0;
  data[1] = ay / 16384.0;
  data[2] = az / 16384.0;

  float totalAcc = sqrt(
    data[0]*data[0] +
    data[1]*data[1] +
    data[2]*data[2]
  );

  filteredAcc = 0.7 * filteredAcc + 0.3 * totalAcc;

  if (impactDetected) {
    if (filteredAcc > highThreshold) {
      severity = "High";
    } 
    else if (filteredAcc > mediumThreshold) {
      severity = "Medium";
    }
    else {
      severity = "Low";
    }
  }

  digitalWrite(ledPin, impactDetected ? HIGH : LOW);

 if (impactDetected && !impactSent) {

  impactSent = true;

  // GPS
  if (gps.location.isValid()) {
    data[3] = gps.location.lat();
    data[4] = gps.location.lng();
  } else {
    data[3] = 0;
    data[4] = 0;
  }

  float speed = gps.speed.isValid() ? gps.speed.kmph() : 0;

  Serial.print(data[0]); Serial.print(",");
  Serial.print(data[1]); Serial.print(",");
  Serial.print(data[2]); Serial.print(",");
  Serial.print(speed); Serial.print(",");
  Serial.print(data[3], 6); Serial.print(",");
  Serial.print(data[4], 6); Serial.print(",");
  Serial.println(severity);
}

  delay(200);
}
