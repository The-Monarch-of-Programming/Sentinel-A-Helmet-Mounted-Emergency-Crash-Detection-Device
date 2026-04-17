#include <Wire.h>
#include <MPU6050.h>
#include <TinyGPS++.h>
#include <SoftwareSerial.h>

MPU6050 mpu;
TinyGPSPlus gps;
SoftwareSerial gpsSerial(4, 5);

int impactPin = 7;
int ledPin = 13;

int confirmCount = 0;
int confirmThreshold = 4;

float data[3];

float lowThreshold = 1;
float mediumThreshold = 2;
float highThreshold = 3;

float filteredAcc = 0;

void setup() {
  Serial.begin(9600);
  Wire.begin();
  gpsSerial.begin(9600);

  pinMode(impactPin, INPUT);
  pinMode(ledPin, OUTPUT);

  mpu.initialize();
  delay(1000);

  if (!mpu.testConnection()) {
    while (1);
  }
}

void loop() {

  while (gpsSerial.available()) {
    gps.encode(gpsSerial.read());
  }

  int impact = digitalRead(impactPin);

  if (impact == LOW) confirmCount++;
  else confirmCount = 0;

  bool impactDetected = (confirmCount >= confirmThreshold);

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
  String severity = "None"; 

  if (impactDetected) {
    if (filteredAcc > highThreshold) severity = "High";
    else if (filteredAcc > mediumThreshold) severity = "Medium";
    else severity = "Low";
  }

  digitalWrite(ledPin, impactDetected ? HIGH : LOW);

  float lat = gps.location.isValid() ? gps.location.lat() : 0;
  float lng = gps.location.isValid() ? gps.location.lng() : 0;
  float speed = gps.speed.isValid() ? gps.speed.kmph() : 0;
 
  Serial.print(data[0], 3); Serial.print(",");
  Serial.print(data[1], 3); Serial.print(",");
  Serial.print(data[2], 3); Serial.print(",");
  Serial.print(speed, 2); Serial.print(",");
  Serial.print(lat, 6); Serial.print(",");
  Serial.print(lng, 6); Serial.print(",");
  Serial.println(severity);

  delay(300);

}
