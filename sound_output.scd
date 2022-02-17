// Start the local server
s.boot;

// Defining the first Synth
(
SynthDef("main-synth", {| freq= #[300], mul=1, amp=0.125, out = 0|
	Out.ar(out, Mix(SinOsc.ar(freq,mul,amp)));
}).add;
)

// Defining the second Synth
(
SynthDef("help-synth", {| freq= #[100], mul=1, amp=0.25, out = 0|
	Out.ar(out, Mix(SinOsc.ar(freq,mul,amp)));
}).add;
)

// Show all serial ports available
SerialPort.devices;

// Creating the port at the port where the arduino is connected
(
~port = SerialPort("/dev/tty.usbmodem14201")
)

// Main routine to get sensor values
(

// Intialize variables for different sensors
~valSonarY = 0;
~valSonarX = 0;
~valForce = 0;
~valSound = 0;
~valAngle = 0;

// Extra variables for calculating the moving average of the current sound reading
~valSoundMA = [];
~valMA = 0;
~valSum = 0;

// Char array to differentiate between different sensors
~charArray = [];
~getValues = Routine.new({
	var ascii;
	{
		// Read the ascii char from the serial port
		ascii = ~port.read.asAscii;
		if(ascii.isDecDigit, {
			~charArray = ~charArray.add(ascii);
		});
		if(ascii == $x, {
			// Convert the array to a numerical value
			// For coordinate X we want to map a distance between 0 and 30 to a frequency add on from 0 to 100
			~valSonarX = ((~charArray.collect(_.digit).convertDigits)-0)*((100-0)/(30-0))+0;
			// Empty the array
			~charArray = [];
		});
		if(ascii == $y, {
			// Convert the array to a numerical value
			// For coordinate Y we want to map a distance between 0 and 30 to a frequency add on from 0 to 100
			~valSonarY = ((~charArray.collect(_.digit).convertDigits)-0)*((100-0)/(30-0))+0;
			// Empty the array
			~charArray = [];
		});
		if(ascii == $p, {
			// Convert the array to a numerical value
			// For the fsr reading we want to map the pressure between 0 and 850 to an amplitude between 0 to 1
			~valForce = ((~charArray.collect(_.digit).convertDigits)-0)*((1-0)/(850-0))+0;
			// Empty the array
			~charArray = [];
		});
		if(ascii == $s, {
			// Convert the array to a numerical value
			// For the sound reading we want to calculate the moving average over 200 values to get consistent readings.
			~valSound = (~charArray.collect(_.digit).convertDigits);
			if(~valSoundMA.size >= 200, {
				~valSum = ~valSum - ~valSoundMA.removeAt(0);
			});
			if(~valSoundMA.size < 200, {
				~valSum = ~valSum + ~valSound;
				~valSoundMA = ~valSoundMA.add(~valSound);
			});
			~valMA = ~valSum / ~valSoundMA.size;
			// Empty the array
			~charArray = [];
		});
		if(ascii == $a, {
			// Convert the array to a numerical value
			// For the accelerometer reading we want to map the angle between20 and 130 to an amplitude between 0 to 1
			~valAngle = (((~charArray.collect(_.digit).convertDigits)-20)*((1-0)/(130-20))+0).abs;
			// Empty the array
			~charArray = [];
		});

	}.loop;
}).play;
)

// Used for printing all the variables
~valSonarX;
~valSonarY;
~valForce;
~valSound;
~valSum;
~valMA;
~valSoundMA;
~valSoundMA.size;
~valCounter;
~valAngle.abs;

// Used stopping the getValues routine
~getValues.stop;


// Intializing the main-synth
~x = Synth("main-synth", [\freq:300]);
~x.set(\freq,300);
~x.set(\amp,0.125);

// Intializing the help-synth
~y = Synth("help-synth", [\freq:400]);
~y.set(\freq,402);
~y.set(\amp,0.5);

// Used for testing purposes
~xFreq = 300 + ~valSonarX;
~yFreq = 400 + ~valSonarY;

// Main routine for controlling the sound output using the readings from different sensors.
(
~control=Routine.new({
	{
		// Add the frequency add on from X and Y coordinate to the intial frequency
		~xFreq = 300 + ~valSonarX;
		~yFreq = 400 + ~valSonarY;
		~x.set(\freq,~xFreq);
		~y.set(\freq,~yFreq);

		// Map the pressure to the amplitude of the X frequency
		~x.set(\amp,~valForce);


		// Make sure the angle reading is right, if it is map it to the amplitude for the Y frequency
		if(~valAngle > 1, {
			~y.set(\amp,0.5);
		}, {
			~y.set(\amp,~valAngle.abs);
		});

		// If the sound moving average is below 50 (not writing) turn the amplitude to zero
		if(~valMA < 50,{
			~x.set(\amp,0);
			~y.set(\amp,0);
		});
		// Reset to initial frequency
		~xFreq = 300;
		~yFreq = 400;
		// Wait for a bit
		0.01.wait;
	}.loop;
}).play;
)

// Used to stop the control routine
~control.stop;

// Used to close the serial port
SerialPort.closeAll;

// Used to quit the server
s.quit;
