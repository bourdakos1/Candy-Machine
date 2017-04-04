var io = require('socket.io-client');
var five = require("johnny-five");
var Raspi = require("raspi-io");

/******************************************************************************
* Socket
*******************************************************************************/
const socket = io.connect('http://candy-machine.mybluemix.net');
socket.on('connect', function () {
    console.log("socket connected");
});

socket.on('dispense', function(data) {
    console.log(data["sentiment"]);
    dispense(data["sentiment"]);
});

/******************************************************************************
* Control motor
*******************************************************************************/
var board = new five.Board({
    io: new Raspi()
});

function dispense(sentiment) {
    var m1 = new five.Motor({
        controller: "PCA9685",
        frequency: 1600, // Hz
        pins: {
            pwm: 8,
            dir: 9,
            cdir: 10,
        },
        address: 0x60
    });

    var m3 = new five.Motor({
        controller: "PCA9685",
        frequency: 1600, // Hz
        pins: {
            pwm: 2,
            dir: 3,
            cdir: 4,
        },
        address: 0x60
    });

    // m2 = pwm: 13, dir: 12, cdir: 11
    // m4 = pwm: 7, dir: 6, cdir: 5

    if (sentiment == "negative") {
        m3.forward(255);
        board.wait(500, function() {
            m3.stop();
        });
    } else {
        m1.forward(255);
        board.wait(500, function() {
            m1.stop();
        });
    }
}
