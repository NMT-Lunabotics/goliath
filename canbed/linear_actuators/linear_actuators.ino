 #include <Arduino.h>

// Define pin numbers
const int spd = 6;
const int dir = 7;
const int potPin = A0;

int tgt = 100;      // in mm

int pwm = 200;      // speed, in pwm TODO change this to mm/s
int stroke = 250;   // stroke length, in mm
int potMin = 34;    // Calibrated, pot val at min stroke
int potMax = 945;   // Calibrated, pot val at max stroke
float weight = 0.2; // How much old readings influence new ones

float kP=.4;
float kI=.00;
float kD=.0;
float derivative;
float error;
float prevError=0;
float integral=0;
float threshold= 20;
float threshold2=1;
void setup() {
  Serial.begin(9600);
  pinMode(spd, OUTPUT);
  pinMode(dir, OUTPUT);
  pinMode(potPin, INPUT);

  int lastValue = analogRead(potPin);
  while (true) {
    // Handle new readings
    int newVal = analogRead(potPin);

    if (abs(newVal - lastValue) > 20) {
      // Serial.println("Ignoring jump");
      lastValue = newVal;
      delay(50);
      continue;
    }

    lastValue = newVal;

    int pos = map(newVal, potMin, potMax, 0, stroke);
    // Serial.print(newVal);
    // Serial.print("\t:\t");
    Serial.println(pos);

    delay(50);
    error=tgt-pos;
    if(error<threshold&&(error>error+threshold2||error>error-threshold2)){
    	error=tgt-pos;
    	derivative=error-prevError;
    	prevError=error;
    	integral+=error;
    	int output=kP*error+kI*integral+kD*derivative;
    	output=constrain(output,-200,200);
        Serial.println(output);
    }

    // When here, output is between -200 and 200. Output 0 will stop;
  	digitalWrite(dir, output > 0);
    if (output == 0) {
      analogWrite(spd, 0);
    } else {
      analogWrite(spd, map(abs(output), 0, 200, 30, 200));
    }
    delay(50);
  }
}

void loop() {}
