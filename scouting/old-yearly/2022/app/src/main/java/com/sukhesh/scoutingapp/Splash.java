    package com.sukhesh.scoutingapp;

    import android.content.Intent;
    import android.content.res.Configuration;
    import android.os.Bundle;
    import android.os.Handler;
    import android.os.Looper;

    import androidx.appcompat.app.AppCompatActivity;

    public class Splash extends AppCompatActivity {
        //Loading screen lmaoo its literally just for looks its not actually waiting for anything to load
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        Configuration config = getResources().getConfiguration();
        if (config.smallestScreenWidthDp >= 600) {
            setContentView(R.layout.activity_splash);
        } else {
            setContentView(R.layout.activity_splash_phone);
        }
        //hide annoying toolbar

        //Run the splash screen for 4 seconds and switch to main activity
        new Handler(Looper.getMainLooper()).postDelayed(() -> {
            Intent intent = new Intent(Splash.this, MainActivity.class);
            startActivity(intent);
            finish();
        }, 00);
    }
}