// package com.example.water_boiler_rfid_labeler;

// import android.os.Bundle;
// import android.util.Log;
// import android.view.KeyEvent;
// import io.flutter.embedding.android.FlutterActivity;
// import io.flutter.plugin.common.MethodChannel;

// public class MainActivity extends FlutterActivity {
//     private static final String CHANNEL = "com.example.my_rfid_plugin/key_events";

//     @Override
//     protected void onCreate(Bundle savedInstanceState) {
//         super.onCreate(savedInstanceState);
//         new MethodChannel(getFlutterEngine().getDartExecutor().getBinaryMessenger(), CHANNEL).setMethodCallHandler(
//                 (call, result) -> {
//                     // Handle method calls from Flutter if needed
//                 });
//     }

//     @Override
//     public boolean onKeyDown(int keyCode, KeyEvent event) {
//         Log.d("MainActivity", "Key down: " + keyCode);
//         new MethodChannel(getFlutterEngine().getDartExecutor().getBinaryMessenger(), CHANNEL).invokeMethod("onKeyDown",
//                 keyCode);
//         return super.onKeyDown(keyCode, event);
//     }

//     @Override
//     public boolean onKeyUp(int keyCode, KeyEvent event) {
//         Log.d("MainActivity", "Key up: " + keyCode);
//         new MethodChannel(getFlutterEngine().getDartExecutor().getBinaryMessenger(), CHANNEL).invokeMethod("onKeyUp",
//                 keyCode);
//         return super.onKeyUp(keyCode, event);
//     }
// }
package com.example.water_boiler_rfid_labeler;

import android.util.Log;
import android.view.KeyEvent;

import androidx.annotation.NonNull;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {
    private static final String TAG = "MainActivity";
    private static final String KEY_EVENT_CHANNEL = "com.example.my_rfid_plugin/key_events";

    private MethodChannel keyEventChannel;

    // C66 tetik tuşları (çoğu model: 293/294; bazılarında 131/132)
    private static final int[] SCAN_KEYS = new int[] { 131, 132, 293, 294 };

    private boolean isScanKey(int code) {
        for (int k : SCAN_KEYS)
            if (k == code)
                return true;
        return false;
    }

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        Log.d(TAG, "configureFlutterEngine()");
        keyEventChannel = new MethodChannel(
                flutterEngine.getDartExecutor().getBinaryMessenger(),
                KEY_EVENT_CHANNEL);
    }

    @Override
    public boolean dispatchKeyEvent(KeyEvent event) {
        int code = event.getKeyCode();
        int action = event.getAction();
        Log.v(TAG, "dispatchKeyEvent code=" + code + " action=" + action);

        if (isScanKey(code)) {
            if (action == KeyEvent.ACTION_DOWN) {
                Log.d(TAG, "Key down: " + code);
                if (keyEventChannel != null)
                    keyEventChannel.invokeMethod("onKeyDown", code);
                return true; // olayı tükettik
            } else if (action == KeyEvent.ACTION_UP) {
                Log.d(TAG, "Key up  : " + code);
                if (keyEventChannel != null)
                    keyEventChannel.invokeMethod("onKeyUp", code);
                return true; // olayı tükettik
            }
        }
        return super.dispatchKeyEvent(event);
    }

    // Emniyet için fallback (bazı cihazlarda dispatch yerine bunlar tetiklenir)
    @Override
    public boolean onKeyDown(int keyCode, KeyEvent event) {
        Log.v(TAG, "onKeyDown fallback code=" + keyCode);
        if (isScanKey(keyCode)) {
            if (keyEventChannel != null)
                keyEventChannel.invokeMethod("onKeyDown", keyCode);
            return true;
        }
        return super.onKeyDown(keyCode, event);
    }

    @Override
    public boolean onKeyUp(int keyCode, KeyEvent event) {
        Log.v(TAG, "onKeyUp   fallback code=" + keyCode);
        if (isScanKey(keyCode)) {
            if (keyEventChannel != null)
                keyEventChannel.invokeMethod("onKeyUp", keyCode);
            return true;
        }
        return super.onKeyUp(keyCode, event);
    }
}
