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
int confirmThreshold = 4;

float data[5];

float lowThreshold = 2;
float mediumThreshold = 3;
float highThreshold = 4;

float filteredAcc = 0;
String severity = "Low";

int satellites = 0;

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
  }
}

void loop() {

  // READ GPS
  while (gpsSerial.available()) {
    gps.encode(gpsSerial.read());
  }

  satellites = gps.satellites.value();

  // IMPACT SENSOR
  int impact = digitalRead(impactPin);

  if (impact == LOW) confirmCount++;
  else confirmCount = 1;

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

  if (filteredAcc > highThreshold) {
    severity = "High";
  } 
  else if (filteredAcc > mediumThreshold) {
    severity = "Medium";
  }
  else if (filteredAcc > lowThreshold) {
    severity = "Low";
  }
  else {
    severity = "None";
  }

  digitalWrite(ledPin, impactDetected ? HIGH : LOW);

  // GPS VALUES
  float lat = 0;
  float lng = 0;

  if (gps.location.isValid()) {
    lat = gps.location.lat();
    lng = gps.location.lng();
  }

  float speed = gps.speed.isValid() ? gps.speed.kmph() : 0;

  Serial.print(data[0]); Serial.print(",");
  Serial.print(data[1]); Serial.print(",");
  Serial.print(data[2]); Serial.print(",");
  Serial.print(speed); Serial.print(",");
  Serial.print(lat, 6); Serial.print(",");
  Serial.print(lng, 6); Serial.print(",");
  
  Serial.println(severity);

  delay(500);
}
