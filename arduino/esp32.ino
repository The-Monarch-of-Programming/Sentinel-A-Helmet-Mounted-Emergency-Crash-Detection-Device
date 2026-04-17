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
String severity = "None";
String status = "idle";

bool crashSent = false;
unsigned long lastCrashTime = 0;
int cooldown = 10000; // 10 seconds

String getTimestamp() {
  struct tm timeinfo;

  if (!getLocalTime(&timeinfo)) return "N/A";

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

    data.replace("\r", "");
    data.replace("\n", "");

    if (data.length() == 0) return;

    // ===== SAFE PARSING =====
    int i1 = data.indexOf(',');
    int i2 = data.indexOf(',', i1 + 1);
    int i3 = data.indexOf(',', i2 + 1);
    int i4 = data.indexOf(',', i3 + 1);
    int i5 = data.indexOf(',', i4 + 1);
    int i6 = data.indexOf(',', i5 + 1);

    if (i6 == -1) {
      Serial.println("Parse FAILED");
      return;
    }

    ax = data.substring(0, i1).toFloat();
    ay = data.substring(i1 + 1, i2).toFloat();
    az = data.substring(i2 + 1, i3).toFloat();
    speed = data.substring(i3 + 1, i4).toFloat();
    lat = data.substring(i4 + 1, i5).toFloat();
    lng = data.substring(i5 + 1, i6).toFloat();
    severity = data.substring(i6 + 1);
    severity.trim();

    // ===== STATUS =====
    if (severity == "Low") status = "responded";
    else if (severity == "Medium" || severity == "High") status = "ongoing";
    else status = "idle";

    Serial.println("Parsed OK");

    // ===== CRASH SEND WITH COOLDOWN =====
    if ((severity == "Low" || severity == "Medium" || severity == "High")) {

      if (!crashSent || millis() - lastCrashTime > cooldown) {
        sendCrash();
        crashSent = true;
        lastCrashTime = millis();
      }
    }

    if (severity == "None") {
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
  json += "\"latitude\": {\"doubleValue\": " + String(lat, 6) + "},";
  json += "\"longitude\": {\"doubleValue\": " + String(lng, 6) + "},";
  json += "\"severity\": {\"stringValue\": \"" + severity + "\"},";
  json += "\"status\": {\"stringValue\": \"" + status + "\"}";

  json += "} }";

  Serial.println("\n[CRASH SENT]");
  Serial.println(json);

  int code = http.POST(json);
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

  http.PATCH(json);
  http.end();
}
