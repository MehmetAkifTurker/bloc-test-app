// package com.example.my_rfid_plugin;

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
//             (call, result) -> {
//                 // Handle method calls from Flutter if needed
//             }
//         );
//     }

//     @Override
//     public boolean onKeyDown(int keyCode, KeyEvent event) {
//         Log.e("MainActivity", "Key down: " + keyCode);
//         new MethodChannel(getFlutterEngine().getDartExecutor().getBinaryMessenger(), CHANNEL).invokeMethod("onKeyDown", keyCode);
//         return super.onKeyDown(keyCode, event);
//     }

//     @Override
//     public boolean onKeyUp(int keyCode, KeyEvent event) {
//         Log.e("MainActivity", "Key up: " + keyCode);
//         new MethodChannel(getFlutterEngine().getDartExecutor().getBinaryMessenger(), CHANNEL).invokeMethod("onKeyUp", keyCode);
//         return super.onKeyUp(keyCode, event);
//     }
// }