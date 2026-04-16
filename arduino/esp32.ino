#include <WiFi.h>
#include <HTTPClient.h>
#include "time.h"

HardwareSerial unoSerial(2);

const char* ssid = "VirusInstaller_4G";
const char* password = "D@J#A7845";

String projectId = "sentinel-d37fb";
String apiKey = "YOUR_API_KEY"; // PUT REAL KEY

String crashURL = "https://firestore.googleapis.com/v1/projects/" + projectId +
                  "/databases/(default)/documents/crash_records";

String deviceURL = "https://firestore.googleapis.com/v1/projects/" + projectId +
                   "/databases/(default)/documents/devices/readings?key=" + apiKey;

String driverID = "qwbOd4ofXQTnQJ1m8PLlHxha2MQ2";

float ax, ay, az, speed, lat, lng;
String severity = "";
String status = "";

String getTimestamp() {
  struct tm timeinfo;

  int retry = 0;
  while (!getLocalTime(&timeinfo) && retry < 5) {
    delay(1000);
    retry++;
  }

  if (retry >= 5) return "N/A";

  char buffer[100];
  strftime(buffer, sizeof(buffer),
           "%B %d, %Y at %I:%M:%S %p UTC+8",
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

  if (!unoSerial.available()) return;

  String data = unoSerial.readStringUntil('\n');
  data.trim();

  if (data.length() == 0) return;

  Serial.println("RX: " + data);

  char sev[15] = {0};

  int parsed = sscanf(data.c_str(),
                      "%f,%f,%f,%f,%f,%f,%14s",
                      &ax, &ay, &az, &speed, &lat, &lng, sev);

  if (parsed != 7) {
    Serial.println("Parse FAILED");
    return;
  }

  severity = String(sev);

  if (severity == "Low") {
    status = "responded";
  } else if (severity == "Medium" || severity == "High") {
    status = "ongoing";
  } else {
    status = "unknown";
  }

  Serial.println("Severity: " + severity);
  Serial.println("Status: " + status);

  sendCrash();
  delay(300);
  sendDevice();
}

void sendCrash() {

  if (WiFi.status() != WL_CONNECTED) return;

  HTTPClient http;

  String url = crashURL + "?key=" + apiKey;
  http.begin(url);
  http.addHeader("Content-Type", "application/json");
  http.setTimeout(10000);

  String timestamp = getTimestamp();

  String json = "{ \"fields\": {";

  json += "\"date\": {\"stringValue\": \"" + timestamp + "\"},";
  json += "\"dispatcher_id\": {\"stringValue\": \"\"},";
  json += "\"driver_id\": {\"stringValue\": \"" + driverID + "\"},";
  json += "\"hospital\": {\"stringValue\": \"\"},";

  json += "\"latitude\": {\"stringValue\": \"" + String(lat, 6) + "\"},";
  json += "\"longitude\": {\"stringValue\": \"" + String(lng, 6) + "\"},";

  json += "\"respondedAt\": {\"nullValue\": null},";

  json += "\"severity\": {\"stringValue\": \"" + severity + "\"},";
  json += "\"status\": {\"stringValue\": \"" + status + "\"}";

  json += "} }";

  Serial.println("Crash JSON:");
  Serial.println(json);

  int code = http.POST(json);

  Serial.print("Crash Response: ");
  Serial.println(code);

  Serial.println(http.getString());

  http.end();
}

void sendDevice() {

  if (WiFi.status() != WL_CONNECTED) return;

  HTTPClient http;

  http.begin(deviceURL);
  http.addHeader("Content-Type", "application/json");
  http.setTimeout(10000);

  float vectorMagnitude = sqrt(ax * ax + ay * ay + az * az);

  String json = "{ \"fields\": {";

  json += "\"ax\": {\"doubleValue\": " + String(ax, 4) + "},";
  json += "\"ay\": {\"doubleValue\": " + String(ay, 4) + "},";
  json += "\"az\": {\"doubleValue\": " + String(az, 4) + "},";
  json += "\"severity\": {\"stringValue\": \"" + severity + "\"},";
  json += "\"vector_magnitude\": {\"doubleValue\": " + String(vectorMagnitude, 4) + "}";

  json += "} }";

  Serial.println("Device JSON:");
  Serial.println(json);

  int code = http.PATCH(json);

  Serial.print("Device Response: ");
  Serial.println(code);

  String response = http.getString();
  Serial.println(response);

  http.end();
}
