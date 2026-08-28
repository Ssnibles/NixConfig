/*
  ESP32 Arduino Starter Sketch
  ----------------------------
  Demonstrates Serial communication, GPIO output (LED), and Wi-Fi scanning.
*/

#include <WiFi.h>

#ifndef LED_BUILTIN
#define LED_BUILTIN 2
#endif

void setup() {
  Serial.begin(115200);
  delay(1000);

  Serial.println("\n=========================================");
  Serial.println("🚀 ESP32 Arduino Initialization");
  Serial.println("=========================================");

  pinMode(LED_BUILTIN, OUTPUT);

  // Initialize Wi-Fi station mode
  WiFi.mode(WIFI_STA);
  WiFi.disconnect();
  delay(100);

  Serial.println("⚡ Setup complete!");
}

void loop() {
  // Blink LED
  digitalWrite(LED_BUILTIN, HIGH);
  Serial.println("💡 LED ON - Performing Wi-Fi scan...");
  
  int n = WiFi.scanNetworks();
  if (n == 0) {
    Serial.println("  No Wi-Fi networks found.");
  } else {
    Serial.printf("  Found %d Wi-Fi network(s):\n", n);
    for (int i = 0; i < n; ++i) {
      Serial.printf("   %2d: %s (%d dBm)\n", i + 1, WiFi.SSID(i).c_str(), WiFi.RSSI(i));
      delay(10);
    }
  }

  digitalWrite(LED_BUILTIN, LOW);
  Serial.println("💤 LED OFF - Sleeping for 5 seconds...\n");
  delay(5000);
}
