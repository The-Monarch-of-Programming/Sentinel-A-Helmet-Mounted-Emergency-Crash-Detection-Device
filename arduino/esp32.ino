#include <WiFi.h>
#include <HTTPClient.h>
#include "time.h"

// UART from Arduino Uno
HardwareSerial unoSerial(2); // RX2 = GPIO16

// WIFI
const char* ssid = "T.I.P.ian Student";
const char* password = "";

// FIREBASE
String projectId = "sentinel-d37fb";
String apiKey = "AIzaSyCJdTgtmY2KMM6YOXxzAMrshH859Sux-X8";

String baseURL = "https://firestore.googleapis.com/v1/projects/" + projectId +
                 "/databases/(default)/documents/crash_records/";

// NTP Time
const char* ntpServer = "pool.ntp.org";
const long gmtOffset_sec = 28800; // Philippines UTC+8
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

  // Initialize time
  configTime(gmtOffset_sec, daylightOffset_sec, ntpServer);
}

void loop() {

  if (unoSerial.available()) {
    String incomingData = unoSerial.readStringUntil('\n');
    incomingData.trim();

    Serial.println("Received: " + incomingData);

    // ax,ay,az,speed,lat,lng,severity
    float ax, ay, az, speed, lat, lng;
    char severityChar[10];

    int parsed = sscanf(incomingData.c_str(),
                        "%f,%f,%f,%f,%f,%f,%s",
                        &ax, &ay, &az, &speed, &lat, &lng, severityChar);

    if (parsed == 7) {
      String severity = String(severityChar);

      sendToFirestore(ax, ay, az, speed, lat, lng, severity);
    } else {
      Serial.println("Parsing failed!");
    }
  }
}

// SEND TO FIRESTORE
void sendToFirestore(float ax, float ay, float az, float speed,
                     float lat, float lng, String severity) {

  if (WiFi.status() == WL_CONNECTED) {
    HTTPClient http;

    String url = baseURL + "?key=" + apiKey;
    http.begin(url);
    http.addHeader("Content-Type", "application/json");

    // Google Maps Link
    String mapsLink = "https://www.google.com/maps?q=" +
                      String(lat, 6) + "," + String(lng, 6);

    // Status Logic
    String status;
    if (severity == "LOW") {
      status = "RESPONDED";
    } else if (severity == "MEDIUM" || severity == "HIGH") {
      status = "ON GOING";
    } else {
      status = "UNKNOWN";
    }

    // Timestamp
    struct tm timeinfo;
    String timestamp = "N/A";

    if (getLocalTime(&timeinfo)) {
      char timeString[30];
      strftime(timeString, sizeof(timeString), "%Y-%m-%d %H:%M:%S", &timeinfo);
      timestamp = String(timeString);
    }

    // JSON Payload
    String jsonPayload = "{ \"fields\": {";

    jsonPayload += "\"ax\": {\"doubleValue\": " + String(ax, 3) + "},";
    jsonPayload += "\"ay\": {\"doubleValue\": " + String(ay, 3) + "},";
    jsonPayload += "\"az\": {\"doubleValue\": " + String(az, 3) + "},";
    jsonPayload += "\"speed\": {\"doubleValue\": " + String(speed, 2) + "},";

    jsonPayload += "\"latitude\": {\"doubleValue\": " + String(lat, 6) + "},";
    jsonPayload += "\"longitude\": {\"doubleValue\": " + String(lng, 6) + "},";

    jsonPayload += "\"maps_link\": {\"stringValue\": \"" + mapsLink + "\"},";

    jsonPayload += "\"severity\": {\"stringValue\": \"" + severity + "\"},";
    jsonPayload += "\"status\": {\"stringValue\": \"" + status + "\"},";
    jsonPayload += "\"timestamp\": {\"stringValue\": \"" + timestamp + "\"}";

    jsonPayload += "} }";

    int httpResponseCode = http.POST(jsonPayload);

    Serial.print("HTTP Response: ");
    Serial.println(httpResponseCode);

    http.end();
  }
}