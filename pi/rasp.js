const watson = require('watson-developer-cloud');
const mic = require('mic');
var io = require('socket.io-client');
// var PythonShell = require('python-shell');
var five = require("johnny-five");
var Raspi = require("raspi-io");
// const GPIO = require('onoff').Gpio;
const config = require('./config.js');
const BOUNCE_DURATION = 300;

/******************************************************************************
* Create Watson Services
*******************************************************************************/
const speechToText = watson.speech_to_text({
  username: config.STTUsername,
  password: config.STTPassword,
  version: 'v1'
});

/******************************************************************************
* Configuring the Microphone
*******************************************************************************/
const micParams = {
  rate: 44100,
  channels: 2,
  debug: false,
  exitOnSilence: 6
}
const micInstance = mic(micParams);
const micInputStream = micInstance.getAudioStream();

micInputStream.on('pauseComplete', ()=> {
  console.log('The microphone paused');
});

micInputStream.on('resumeComplete', ()=> {
  console.log('The microphone resumed');
});

micInstance.start();
micInstance.pause();

/******************************************************************************
* Handle Button
*******************************************************************************/
// var time = new Date().getTime();
// var last_state = 1;
//
// var button = new GPIO(18, 'in', 'both');
// button.watch(function(err, state) {
//   if(state == 1 && last_state != 1) {
//     // console.log('p' + time + BOUNCE_DURATION + ' < ' + new Date().getTime());
//     if (time + BOUNCE_DURATION < new Date().getTime()) {
//       time = new Date().getTime();
//       last_state = 1;
//       micInstance.pause();
//       console.log('paused');
//     }
//   } else if(state != 1 && last_state == 1) {
//     // console.log('n' + time + BOUNCE_DURATION + ' < ' + new Date().getTime());
//     if (time + BOUNCE_DURATION < new Date().getTime()) {
//       time = new Date().getTime();
//       last_state = 0;
//       micInstance.resume();
//       console.log('listening...');
//     }
//   }
// });

/******************************************************************************
* Speech To Text
*******************************************************************************/
const textStream = micInputStream.pipe(
  speechToText.createRecognizeStream({
    content_type: 'audio/l16; rate=44100; channels=2',
  })).setEncoding('utf8');

textStream.on('data', function(user_speech_text) {
  console.log('Watson hears:', user_speech_text);
});

/******************************************************************************
* Socket
*******************************************************************************/

const socket = io.connect('http://candy-machine.mybluemix.net');
socket.on('connect', function () {
  console.log("socket connected");
});

// TODO: fix miss-spelling
socket.on('dispence', function(data) {
    console.log('Dispense Candy!');
    console.log(data["sentiment"]);
    dispense(data["sentiment"]);
});

/******************************************************************************
* Run python to control motors
*******************************************************************************/
// function dispense(sentiment) {
//   var options = {
//     // pythonPath: 'python3',
//     args: [sentiment]
//   };
//   var pyshell = PythonShell.run('dispense.py', options, function (err, results) {
//     if (err) throw err;
//   });
//
//   pyshell.on('message', function (message) {
//     // received a message sent from the Python script
//     console.log(message);
//   });
// }

/******************************************************************************
* Control motor
*******************************************************************************/
var board = new five.Board({
  io: new Raspi()
});

board.on("ready", function() {
  var m1 = new five.Motor({
    controller: "PCA9685",
    frequency: 200, // Hz
    pins: {
      pwm: 8,
      dir: 9,
      cdir: 10,
    },
    address: 0x60
  });

  var m2 = new five.Motor({
    controller: "PCA9685",
    frequency: 200, // Hz
    pins: {
      pwm: 13,
      dir: 12,
      cdir: 11,
    },
    address: 0x60
  });

  var m3 = new five.Motor({
    controller: "PCA9685",
    frequency: 200, // Hz
    pins: {
      pwm: 2,
      dir: 3,
      cdir: 4,
    },
    address: 0x60
  });

  var m4 = new five.Motor({
    controller: "PCA9685",
    frequency: 200, // Hz
    pins: {
      pwm: 7,
      dir: 6,
      cdir: 5,
    },
    address: 0x60
  });
});

function dispense(sentiment) {
  m3.forward(255);
  board.wait(500, function() {
    m3.release();
  });
}
