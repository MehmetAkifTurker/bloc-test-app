package com.example.water_boiler_rfid_labeler;

// import android.content.Context;
// import android.os.Handler;
// import android.os.Message;
// import android.text.TextUtils;
// import android.util.Log;
// import android.view.KeyEvent;

// import com.rscja.deviceapi.interfaces.KeyEventCallback;
// import io.flutter.embedding.android.FlutterActivity;

// public class MainActivity extends FlutterActivity {

//     String TAG="MainActivity_2D";

//     @Override
//     public boolean onKeyDown(int keyCode, KeyEvent event) {
//         Log.e(TAG, "Button down " + keyCode);
//         return super.onKeyDown(keyCode, event);
//     }

//     @Override
//     public boolean onKeyUp(int keyCode, KeyEvent event) {
//         Log.e(TAG, "Button up" + keyCode);
//         return super.onKeyUp(keyCode, event);
//     }

// }

import android.os.Bundle;
import android.util.Log;
import android.view.KeyEvent;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "com.example.my_rfid_plugin/key_events";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        new MethodChannel(getFlutterEngine().getDartExecutor().getBinaryMessenger(), CHANNEL).setMethodCallHandler(
                (call, result) -> {
                    // Handle method calls from Flutter if needed
                });
    }

    @Override
    public boolean onKeyDown(int keyCode, KeyEvent event) {
        Log.d("MainActivity", "Key down: " + keyCode);
        new MethodChannel(getFlutterEngine().getDartExecutor().getBinaryMessenger(), CHANNEL).invokeMethod("onKeyDown",
                keyCode);
        return super.onKeyDown(keyCode, event);
    }

    @Override
    public boolean onKeyUp(int keyCode, KeyEvent event) {
        Log.d("MainActivity", "Key up: " + keyCode);
        new MethodChannel(getFlutterEngine().getDartExecutor().getBinaryMessenger(), CHANNEL).invokeMethod("onKeyUp",
                keyCode);
        return super.onKeyUp(keyCode, event);
    }
}
