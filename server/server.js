var app = require('express')();
var server = require('http').createServer(app);
var io = require('socket.io')(server);
var bodyParser = require('body-parser');

app.use(bodyParser.json());

var NaturalLanguageUnderstandingV1 = require('watson-developer-cloud/natural-language-understanding/v1.js');

var nlu = new NaturalLanguageUnderstandingV1({
    username: '2ca20d44-c07c-41da-bfaf-7666b2c59c7b',
    password: '24bgsQra3sf4',
    version_date: NaturalLanguageUnderstandingV1.VERSION_DATE_2017_02_27
});

app.post("/sentiment", function (req, res) {
    console.log(req.body)
    nlu.analyze({
        'text': req.body.text,
        'features': {
            'sentiment': {}
        }
    }, function(err, response) {
        if (err) {
            res.send({'error': err});
        } else {
            io.emit('dispense', {'sentiment': response.sentiment.document.label});
            res.send({'sentiment': response.sentiment.document.label});
        }
    });
});

var port = process.env.PORT || 5000
server.listen(port, function() {
    console.log("To view your app, open this link in your browser: http://localhost:" + port);
});
