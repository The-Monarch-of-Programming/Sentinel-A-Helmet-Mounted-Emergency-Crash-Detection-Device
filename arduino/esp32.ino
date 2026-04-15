#include <WiFi.h>
#include <HTTPClient.h>
#include "time.h"
#include <math.h>  

// UART from Arduino Uno
HardwareSerial unoSerial(2); // RX2 = GPIO16

// WIFI
const char* ssid = "VirusInstaller_4G";
const char* password = "D@J#A7845";

// FIREBASE
String projectId = "sentinel-d37fb";
String apiKey = "AIzaSyCJdTgtmY2KMM6YOXxzAMrshH859Sux-X8";

String baseURL = "https://firestore.googleapis.com/v1/projects/" + projectId +
                 "/databases/(default)/documents/crash_records/";

String deviceURL = "https://firestore.googleapis.com/v1/projects/" + projectId +
                   "/databases/(default)/documents/devices/";

String driverID = "qwbOd4ofXQTnQJ1m8PLlHxha2MQ2";

const char* ntpServer = "pool.ntp.org";
const long gmtOffset_sec = 28800;
const int daylightOffset_sec = 0;

void setup() {
  Serial.begin(115200);
  unoSerial.begin(9600, SERIAL_8N1, 16, 17);

  WiFi.begin(ssid, password);
  Serial.print("Connecting");

  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }

  Serial.println("\nWiFi Connected!");

  configTime(gmtOffset_sec, daylightOffset_sec, ntpServer);
}

void loop() {

  if (unoSerial.available()) {
    String incomingData = unoSerial.readStringUntil('\n');
    incomingData.trim();

    Serial.println("Received: " + incomingData);

    float ax, ay, az, speed, lat, lng;
    char severityChar[10];

    int parsed = sscanf(incomingData.c_str(),
                        "%f,%f,%f,%f,%f,%f,%s",
                        &ax, &ay, &az, &speed, &lat, &lng, severityChar);

    if (parsed == 7) {
      String severity = String(severityChar);

      String location = String(lat, 6) + "," + String(lng, 6);

      sendToFirestore(ax, ay, az, speed, severity, location);

      delay(200);

      sendToDevices(ax, ay, az, lat, lng, severity);

    } else {
      Serial.println("Parsing failed!");
    }
  }
}

void sendToFirestore(float ax, float ay, float az, float speed,
                     String severity, String location) {

  if (WiFi.status() == WL_CONNECTED) {
    HTTPClient http;

    String url = baseURL + "?key=" + apiKey;
    http.begin(url);
    http.addHeader("Content-Type", "application/json");

    // Status
    String status;
    if (severity == "Low") {
      status = "responded";
    } else if (severity == "Medium" || severity == "High") {
      status = "ongoing";
    } else {
      status = "unknown";
    }

    // Time formatting
    struct tm timeinfo;
    String timestamp = "N/A";

    if (getLocalTime(&timeinfo)) {
      char timeString[50];
      strftime(timeString, sizeof(timeString),
               "%B %d, %Y at %I:%M:%S %p", &timeinfo);

      timestamp = String(timeString) + " UTC+8";
    }
    
    String jsonPayload = "{ \"fields\": {";

    jsonPayload += "\"date\": {\"stringValue\": \"" + timestamp + "\"},";
    jsonPayload += "\"dispatcher_id\": {\"stringValue\": \"\"},";
    jsonPayload += "\"driver_id\": {\"stringValue\": \"" + driverID + "\"},";
    jsonPayload += "\"hospital\": {\"stringValue\": \"\"},";

    jsonPayload += "\"location\": {\"stringValue\": \"" + location + "\"},";

    jsonPayload += "\"respondedAt\": {\"nullValue\": null},";

    jsonPayload += "\"severity\": {\"stringValue\": \"" + severity + "\"},";
    jsonPayload += "\"status\": {\"stringValue\": \"" + status + "\"}";

    jsonPayload += "} }";

    int httpResponseCode = http.POST(jsonPayload);

    Serial.print("Crash Response: ");
    Serial.println(httpResponseCode);

    http.end();
  }
}

void sendToDevices(float ax, float ay, float az, float lat, float lng, String severity) {

  if (WiFi.status() == WL_CONNECTED) {
    HTTPClient http;

    String url = deviceURL + "?key=" + apiKey;
    http.begin(url);
    http.addHeader("Content-Type", "application/json");

    // Compute vector magnitude
    float vectorMagnitude = sqrt(ax * ax + ay * ay + az * az);

    String jsonPayload = "{ \"fields\": {";

    jsonPayload += "\"driver_id\": {\"stringValue\": \"" + driverID + "\"},";

    jsonPayload += "\"ax\": {\"doubleValue\": " + String(ax, 3) + "},";
    jsonPayload += "\"ay\": {\"doubleValue\": " + String(ay, 3) + "},";
    jsonPayload += "\"az\": {\"doubleValue\": " + String(az, 3) + "},";

    jsonPayload += "\"severity\": {\"stringValue\": \"" + severity + "\"},";

    jsonPayload += "\"vector_magnitude\": {\"doubleValue\": " + String(vectorMagnitude, 3) + "},";

    jsonPayload += "\"latitude\": {\"doubleValue\": " + String(lat, 6) + "},";
    jsonPayload += "\"longitude\": {\"doubleValue\": " + String(lng, 6) + "}";

    jsonPayload += "} }";

    int response = http.POST(jsonPayload);

    Serial.print("Devices Response: ");
    Serial.println(response);

    http.end();
  }
}
