#include <Wire.h>
#include <MPU6050.h>
#include <TinyGPS++.h>
#include <SoftwareSerial.h>

MPU6050 mpu;

TinyGPSPlus gps;
SoftwareSerial gpsSerial(4, 3);

int impactPin = 7;
int ledPin = 13;

int confirmCount = 0;
int confirmThreshold = 3;

float data[5];

bool impactSent = false;

// Thresholds
float lowThreshold = 1;
float highThreshold = 2;

float filteredAcc = 0;

String severity = "NONE";

void setup() {
  Serial.begin(9600);
  Wire.begin();
  gpsSerial.begin(9600);

  pinMode(impactPin, INPUT);
  pinMode(ledPin, OUTPUT);

  mpu.initialize();
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

  data[0] = ax / 16384.0;
  data[1] = ay / 16384.0;
  data[2] = az / 16384.0;

  float totalAcc = sqrt(
    data[0]*data[0] +
    data[1]*data[1] +
    data[2]*data[2]
  );

  filteredAcc = 0.7 * filteredAcc + 0.3 * totalAcc;

  severity = "NONE";

  if (impactDetected) {
    if (filteredAcc > highThreshold) {
      severity = "HIGH";
    } 
    else if (filteredAcc > lowThreshold) {
      severity = "LOW";
    }
    else {
      severity = "NONE";
    }
  }

  digitalWrite(ledPin, impactDetected ? HIGH : LOW);

  if (impactDetected && !impactSent) {

    impactSent = true;

    Serial.println("Impact Detected");

    // GPS
    if (gps.location.isValid() && gps.location.isUpdated()) {
      data[3] = gps.location.lat();
      data[4] = gps.location.lng();
    } else {
      data[3] = 0;
      data[4] = 0;
    }

    float speed = gps.speed.isValid() ? gps.speed.kmph() : 0;

    Serial.print("Severity: ");
    Serial.println(severity);

    Serial.print("Accelerometer: ");
    Serial.print(data[0]); Serial.print(",");
    Serial.print(data[1]); Serial.print(",");
    Serial.print(data[2]); Serial.print(",");
    Serial.println(speed);

    Serial.print("Latitude: ");
    Serial.print(data[3], 6);
    Serial.print(" Longitude: ");
    Serial.println(data[4], 6);
  }

  delay(50);
}
