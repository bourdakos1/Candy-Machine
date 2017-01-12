const watson = require('watson-developer-cloud');
const mic = require('mic');
const GPIO = require('onoff').Gpio;
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
var time = new Date().getTime();
var last_state = 1;

var button = new GPIO(18, 'in', 'both');
button.watch(function(err, state) {
  if(state == 1 && last_state != 1) {
    // console.log('p' + time + BOUNCE_DURATION + ' < ' + new Date().getTime());
    if (time + BOUNCE_DURATION < new Date().getTime()) {
      time = new Date().getTime();
      last_state = 1;
      micInstance.pause();
      console.log('paused');
    }
  } else if(state != 1 && last_state == 1) {
    // console.log('n' + time + BOUNCE_DURATION + ' < ' + new Date().getTime());
    if (time + BOUNCE_DURATION < new Date().getTime()) {
      time = new Date().getTime();
      last_state = 0;
      micInstance.resume();
      console.log('listening...');
    }
  }
});

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
