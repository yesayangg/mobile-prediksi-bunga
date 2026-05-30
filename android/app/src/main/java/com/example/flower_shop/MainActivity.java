package com.example.flower_shop;

import android.view.WindowManager;

import androidx.annotation.NonNull;

import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {
    private static final String SECURITY_CHANNEL = "florashop/security";

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        new MethodChannel(
            flutterEngine.getDartExecutor().getBinaryMessenger(),
            SECURITY_CHANNEL
        ).setMethodCallHandler((call, result) -> {
            if (!"setSecureScreen".equals(call.method)) {
                result.notImplemented();
                return;
            }

            final Boolean enabled = call.arguments();
            runOnUiThread(() -> {
                if (Boolean.TRUE.equals(enabled)) {
                    getWindow().setFlags(
                        WindowManager.LayoutParams.FLAG_SECURE,
                        WindowManager.LayoutParams.FLAG_SECURE
                    );
                } else {
                    getWindow().clearFlags(WindowManager.LayoutParams.FLAG_SECURE);
                }
                result.success(null);
            });
        });
    }
}
