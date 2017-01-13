package com.bourdakos1.candymachine;

import android.Manifest;
import android.content.pm.PackageManager;
import android.support.v4.app.ActivityCompat;
import android.support.v7.app.AppCompatActivity;
import android.os.Bundle;
import android.util.Log;
import android.view.MotionEvent;
import android.view.View;
import android.widget.ImageButton;
import android.widget.ImageView;
import android.widget.TextView;

import com.android.volley.AuthFailureError;
import com.android.volley.Request;
import com.android.volley.RequestQueue;
import com.android.volley.Response;
import com.android.volley.VolleyError;
import com.android.volley.toolbox.StringRequest;
import com.android.volley.toolbox.Volley;
import com.ibm.watson.developer_cloud.android.library.audio.AmplitudeListener;
import com.ibm.watson.developer_cloud.android.library.audio.MicrophoneInputStream;
import com.ibm.watson.developer_cloud.android.library.audio.utils.ContentType;
import com.ibm.watson.developer_cloud.speech_to_text.v1.SpeechToText;
import com.ibm.watson.developer_cloud.speech_to_text.v1.model.RecognizeOptions;
import com.ibm.watson.developer_cloud.speech_to_text.v1.model.SpeechResults;
import com.ibm.watson.developer_cloud.speech_to_text.v1.websocket.RecognizeCallback;

import java.util.HashMap;
import java.util.Map;

public class MainActivity extends AppCompatActivity {
    private static final String TAG = MainActivity.class.getSimpleName();

    private float mLastLevel = 0;
    private Thread mThread;
    private static final int SAMPLE_DELAY = 300;

    private ImageView mImageView;
    private ImageView mImageView2;
    private ImageButton mRecord;
    private TextView mSpeech;

    private String mSpeechFirstPart = "";

    private SpeechToText speechService;

    private MicrophoneInputStream capture;
    private boolean listening = false;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        mRecord = (ImageButton) findViewById(R.id.record);
        mSpeech = (TextView) findViewById(R.id.speech);
        mImageView = (ImageView) findViewById(R.id.level);
        mImageView2 = (ImageView) findViewById(R.id.level2);

        mImageView.animate().scaleX(0).setDuration(0);
        mImageView.animate().scaleY(0).setDuration(0);
        mImageView2.animate().scaleX(0).setDuration(0);
        mImageView2.animate().scaleY(0).setDuration(0);

        if (ActivityCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) {
            ActivityCompat.requestPermissions(this, new String[]{Manifest.permission.RECORD_AUDIO}, 0);
        }

        speechService = initSpeechToTextService();

        mRecord.setOnTouchListener(new View.OnTouchListener() {
            @Override
            public boolean onTouch(View v, MotionEvent event) {
                if (event.getAction() == MotionEvent.ACTION_UP) {
                    // This is needed because it will change by the time the request is made
                    final String text = mSpeech.getText().toString();
                    mRecord.setBackground(getDrawable(R.drawable.watson_red));
                    RequestQueue queue = Volley.newRequestQueue(getApplicationContext());
                    StringRequest sr = new StringRequest(Request.Method.POST,"http://candy-machine.mybluemix.net/sentiment", new Response.Listener<String>() {
                        @Override
                        public void onResponse(String response) {
                            Log.d(TAG, response);
                        }
                    }, new Response.ErrorListener() {
                        @Override
                        public void onErrorResponse(VolleyError error) {

                        }
                    }){
                        @Override
                        protected Map<String,String> getParams(){
                            Map<String,String> params = new HashMap<>();
                            params.put("transcript", text);
                            return params;
                        }

                        @Override
                        public Map<String, String> getHeaders() throws AuthFailureError {
                            Map<String,String> params = new HashMap<>();
                            params.put("Content-Type","application/x-www-form-urlencoded");
                            return params;
                        }
                    };
                    queue.add(sr);

                    mSpeech.setText("Tap & Hold");
                    mSpeechFirstPart = "";
                    listening = false;
                    try {
                        capture.close();
                    } catch (Exception e) {
                        e.printStackTrace();
                    }
                    return true;
                } else {
                    mRecord.setBackground(getDrawable(R.drawable.watson_blue));
                    if(!listening) {
                        listening = true;
                        capture = new MicrophoneInputStream(true);
                        capture.setOnAmplitudeListener(new AmplitudeListener() {
                            @Override
                            public void onSample(double amplitude, double volume) {
                                Log.d(TAG, "amp: " + amplitude + "vol:" + volume);
//                                if (volume > mImageView.getScaleX()) {
//                                    mImageView.setScaleX(volume);
//                                    mImageView.setScaleY(volume);
//                                    mImageView2.setScaleX(volume);
//                                    mImageView2.setScaleY(volume);
//                                    mImageView.animate().scaleX(0).scaleY(0).setDuration(600);
//                                    mImageView2.animate().scaleX(0).scaleY(0).setDuration(1000);
//                                }
                            }
                        });
                        new Thread(new Runnable() {
                            @Override
                            public void run() {
                                try {
                                    speechService.recognizeUsingWebSocket(capture, getRecognizeOptions(), new MicrophoneRecognizeDelegate());
                                } catch (Exception e) {
                                    e.printStackTrace();
                                }
                            }
                        }).start();
                    }
                    return true;
                }
            }
        });
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

    private RecognizeOptions getRecognizeOptions() {
        return new RecognizeOptions.Builder()
                .continuous(true)
                .contentType(ContentType.OPUS.toString())
                .model("en-US_BroadbandModel")
                .interimResults(true)
                .inactivityTimeout(2000)
                .build();
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
                        mSpeech.setText(mSpeechFirstPart + text);
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
        }
    }
}
