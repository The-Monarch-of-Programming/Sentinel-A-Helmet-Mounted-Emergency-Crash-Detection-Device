#include <WiFi.h>
#include <HTTPClient.h>
#include "time.h"
#include <math.h>

HardwareSerial unoSerial(2);

// WIFI
const char* ssid = "VirusInstaller_4G";
const char* password = "D@J#A7845";

// FIREBASE
String projectId = "sentinel-d37fb";
String apiKey = "AIzaSyCJdTgtmY2KMM6YOXxzAMrshH859Sux-X8";

String crashURL = "https://firestore.googleapis.com/v1/projects/" + projectId +
                  "/databases/(default)/documents/crash_records?key=" + apiKey;

String deviceURL = "https://firestore.googleapis.com/v1/projects/" + projectId +
                   "/databases/(default)/documents/devices/readings?key=" + apiKey;

String driverID = "qwbOd4ofXQTnQJ1m8PLlHxha2MQ2";

// DATA
float ax = 0, ay = 0, az = 0;
float speed = 0;
float lat = 0, lng = 0;
String severity = "Low";
String status = "idle";

bool crashSent = false;

String getTimestamp() {
  struct tm timeinfo;

  int retry = 0;
  while (!getLocalTime(&timeinfo) && retry < 5) {
    delay(500);
    retry++;
  }

  if (retry >= 5) return "N/A";

  char buffer[100];
  strftime(buffer, sizeof(buffer),
           "%B %d, %Y %I:%M:%S %p UTC+8",
           &timeinfo);

  return String(buffer);
}

void setup() {
  Serial.begin(115200);
  unoSerial.begin(9600, SERIAL_8N1, 16, 17);

  WiFi.begin(ssid, password);

  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }

  Serial.println("\nWiFi Connected!");
  WiFi.setSleep(false);

  configTime(28800, 0, "pool.ntp.org");
}

void loop() {

  if (unoSerial.available()) {

    String data = unoSerial.readStringUntil('\n');
    data.trim();

    if (data.length() == 0) return;

    char sev[10] = {0};

    int parsed = sscanf(data.c_str(),
                        "%f,%f,%f,%f,%f,%f,%9s",
                        &ax, &ay, &az, &speed, &lat, &lng, sev);

    if (parsed != 7) {
      Serial.println("Parse FAILED");
      return;
    }

    severity = String(sev);

    if (severity == "Low") status = "responded";
    else if (severity == "Medium" || severity == "High") status = "ongoing";
    else status = "idle";

    Serial.print("AX: "); Serial.print(ax, 3);
    Serial.print(" AY: "); Serial.print(ay, 3);
    Serial.print(" AZ: "); Serial.print(az, 3);
    Serial.print(" | LAT: "); Serial.print(lat, 6);
    Serial.print(" LNG: "); Serial.print(lng, 6);
    Serial.print(" | SEV: "); Serial.println(severity);

    if ((severity == "Low" || severity == "Medium" || severity == "High") && !crashSent) {
      sendCrash();
      crashSent = true;
    }

    if (severity == "NONE") {
      crashSent = false;
    }
  }

  sendDevice();

  delay(200);
}

void sendCrash() {

  if (WiFi.status() != WL_CONNECTED) return;

  HTTPClient http;
  http.begin(crashURL);
  http.addHeader("Content-Type", "application/json");

  String json = "{ \"fields\": {";

  json += "\"date\": {\"stringValue\": \"" + getTimestamp() + "\"},";
  json += "\"dispatcher_id\": {\"stringValue\": \"\"},";
  json += "\"driver_id\": {\"stringValue\": \"" + driverID + "\"},";
  json += "\"hospital\": {\"stringValue\": \"\"},";

  json += "\"latitude\": {\"stringValue\": \"" + String(lat, 6) + "\"},";
  json += "\"longitude\": {\"stringValue\": \"" + String(lng, 6) + "\"},";

  json += "\"severity\": {\"stringValue\": \"" + severity + "\"},";
  json += "\"status\": {\"stringValue\": \"" + status + "\"}";

  json += "} }";

  Serial.println("\n[CRASH SENT]");
  Serial.println(json);

  int code = http.POST(json);

  Serial.print("Crash Response: ");
  Serial.println(code);

  http.end();
}

void sendDevice() {

  if (WiFi.status() != WL_CONNECTED) return;

  float magnitude = sqrt(ax * ax + ay * ay + az * az);

  HTTPClient http;
  http.begin(deviceURL);
  http.addHeader("Content-Type", "application/json");

  String json = "{ \"fields\": {";

  json += "\"ax\": {\"doubleValue\": " + String(ax, 3) + "},";
  json += "\"ay\": {\"doubleValue\": " + String(ay, 3) + "},";
  json += "\"az\": {\"doubleValue\": " + String(az, 3) + "},";

  json += "\"latitude\": {\"doubleValue\": " + String(lat, 6) + "},";
  json += "\"longitude\": {\"doubleValue\": " + String(lng, 6) + "},";

  json += "\"severity\": {\"stringValue\": \"" + severity + "\"},";
  json += "\"vector_magnitude\": {\"doubleValue\": " + String(magnitude, 3) + "}";

  json += "} }";

  int code = http.PATCH(json);

  Serial.print("Device update: ");
  Serial.println(code);

  http.end();
}
