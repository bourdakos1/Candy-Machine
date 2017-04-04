import os
import json
from dotenv import load_dotenv
from flask import Flask
from flask import request
from watson_developer_cloud import AuthorizationV1 as WatsonAuthorization
from watson_developer_cloud import AlchemyLanguageV1 as AlchemyLanguage
from flask_socketio import SocketIO, Namespace, emit, join_room

load_dotenv(os.path.join(os.path.dirname(__file__), ".env"))
alchemy = AlchemyLanguage(api_key=os.environ.get("ALCHEMY_API_KEY"))

app = Flask(__name__)
socketio = SocketIO(app)

@app.route("/sentiment", methods=["POST"])
def getSentiment():
    text = request.form["transcript"]
    print(text)
    result = alchemy.sentiment(text=text)
    sentiment = result["docSentiment"]["type"]

    if sentiment == "neutral":
        score = 0
    else:
        score = result["docSentiment"]["score"]

    socketio.emit('dispense', {'sentiment': sentiment})

    return json.dumps({"sentiment": sentiment, "score": score})

port = os.getenv('PORT', '5000')
if __name__ == "__main__":
	socketio.run(app, host='0.0.0.0', port=int(port))
