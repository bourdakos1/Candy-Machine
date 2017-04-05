package com.bourdakos1.candymachine;

import android.Manifest;
import android.content.pm.PackageManager;
import android.support.v4.app.ActivityCompat;
import android.support.v7.app.AppCompatActivity;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.widget.ImageButton;
import android.widget.TextView;

import com.android.volley.RequestQueue;
import com.android.volley.Response;
import com.android.volley.VolleyError;
import com.android.volley.toolbox.JsonObjectRequest;
import com.android.volley.toolbox.Volley;
import com.ibm.watson.developer_cloud.android.library.audio.MicrophoneInputStream;
import com.ibm.watson.developer_cloud.android.library.audio.utils.ContentType;
import com.ibm.watson.developer_cloud.speech_to_text.v1.SpeechToText;
import com.ibm.watson.developer_cloud.speech_to_text.v1.model.RecognizeOptions;
import com.ibm.watson.developer_cloud.speech_to_text.v1.model.SpeechResults;
import com.ibm.watson.developer_cloud.speech_to_text.v1.websocket.RecognizeCallback;

import org.json.JSONException;
import org.json.JSONObject;

public class MainActivity extends AppCompatActivity {
    private static final String TAG = MainActivity.class.getSimpleName();

    private ImageButton mRecord;
    private TextView mSpeech;

    private String mSpeechFirstPart = "";

    private SpeechToText speechService;

    private MicrophoneInputStream capture;

    private boolean streaming = false;
    private boolean waiting = false;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        mRecord = (ImageButton) findViewById(R.id.record);
        mSpeech = (TextView) findViewById(R.id.speech);
        mRecord.setBackground(getDrawable(R.drawable.watson_blue));


        if (ActivityCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) {
            ActivityCompat.requestPermissions(this, new String[]{Manifest.permission.RECORD_AUDIO}, 0);
        }

        speechService = initSpeechToTextService();

        mRecord.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                if (!streaming && !waiting) {
                    mRecord.setBackground(getDrawable(R.drawable.watson_red));
                    streaming = true;
                    startStreaming();
                    mSpeech.setText("Listening...");
                } else if (!waiting) {
                    mRecord.setBackground(getDrawable(R.drawable.watson_blue));
                    streaming = false;
                    waiting = true;
                    stopStreaming();
                }
            }
        });
    }

    private void startStreaming() {
        capture = new MicrophoneInputStream(true);
        new Thread(new Runnable() {
            @Override
            public void run() {
                try {
                    speechService.recognizeUsingWebSocket(
                            capture,
                            new RecognizeOptions.Builder()
                                    .continuous(true)
                                    .contentType(ContentType.OPUS.toString())
                                    .model("en-US_BroadbandModel")
                                    .interimResults(true)
                                    .inactivityTimeout(2000)
                                    .build(),
                            new MicrophoneRecognizeDelegate()
                    );
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }
        }).start();
    }

    private void stopStreaming() {
        // This is needed because it will change by the time the request is made
        try {
            capture.close();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private SpeechToText initSpeechToTextService() {
        SpeechToText service = new SpeechToText();
        String username = getString(R.string.speech_text_username);
        String password = getString(R.string.speech_text_password);
        service.setUsernameAndPassword(username, password);
        service.setEndPoint("https://stream.watsonplatform.net/speech-to-text/api");
        Log.d(TAG, "Service ready");
        return service;
    }

    private class MicrophoneRecognizeDelegate implements RecognizeCallback {
        @Override
        public void onTranscription(SpeechResults speechResults) {
            if (speechResults.getResults().size() > 0) {
                final String text = speechResults.getResults().get(0).getAlternatives().get(0).getTranscript();
                final boolean isFinal = speechResults.getResults().get(0).isFinal();

                runOnUiThread(new Runnable() {
                    @Override
                    public void run() {
                        if (!(mSpeechFirstPart + text).equals("")) {
                            mSpeech.setText(mSpeechFirstPart + text);
                        } else {
                            mSpeech.setText("Listening...");
                        }
                        Log.d(TAG, mSpeech.getText().toString());
                        if (isFinal) {
                            mSpeechFirstPart += text;
                        }
                    }
                });
            }
        }

        @Override public void onConnected() {
            Log.d(TAG, "Listening...");
        }

        @Override public void onError(Exception e) {
            e.printStackTrace();
        }

        @Override public void onDisconnected() {
            Log.d(TAG, "Disconnected");
            mSpeechFirstPart = "";
            final String text = mSpeech.getText().toString();
            RequestQueue queue = Volley.newRequestQueue(getApplicationContext());
            try {
                final JSONObject jsonBody = new JSONObject("{\"text\":\"" + text + "\"}");
                JsonObjectRequest jor = new JsonObjectRequest("http://candy-machine.mybluemix.net/sentiment", jsonBody, new Response.Listener<JSONObject>() {
                    @Override
                    public void onResponse(JSONObject response) {
                        Log.d(TAG, response.toString());
                        try {
                            mSpeech.setText(response.getString("sentiment"));
                            waiting = false;
                        } catch (JSONException je) {
                            je.printStackTrace();
                            mSpeech.setText("Try again");
                            waiting = false;
                        }
                    }
                }, new Response.ErrorListener() {
                    @Override
                    public void onErrorResponse(VolleyError error) {
                        mSpeech.setText("Try again");
                        waiting = false;
                    }
                });
                queue.add(jor);
            } catch (JSONException je) {
                je.printStackTrace();
            }
        }
    }
}
