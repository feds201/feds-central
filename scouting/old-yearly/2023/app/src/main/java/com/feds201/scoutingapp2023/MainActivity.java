package com.feds201.scoutingapp2023;

import androidx.annotation.NonNull;
import androidx.appcompat.app.ActionBarDrawerToggle;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.view.ViewCompat;
import androidx.core.view.WindowInsetsCompat;
import androidx.core.view.WindowInsetsControllerCompat;
import androidx.drawerlayout.widget.DrawerLayout;
import androidx.fragment.app.Fragment;
import androidx.room.Room;

import android.content.res.Configuration;
import android.os.Bundle;
import android.view.Gravity;
import android.view.Menu;
import android.view.MenuItem;

import com.feds201.scoutingapp2023.sql.AppDatabase;
import com.google.android.material.navigation.NavigationView;

public class MainActivity extends AppCompatActivity {
    public DrawerLayout drawerLayout;
    public ActionBarDrawerToggle actionBarDrawerToggle;

    public static AppDatabase app_db;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        app_db = Room.databaseBuilder(getApplicationContext(), AppDatabase.class, "matches-database").allowMainThreadQueries().build();

        Configuration config = getResources().getConfiguration();
        if (config.smallestScreenWidthDp >= 600) {
            setTheme(R.style.Theme_Tablet);
        } else {
            setTheme(R.style.Theme_Phone);
        }

        super.onCreate(savedInstanceState);
        hideSystemBars();
        setContentView(R.layout.activity_main);

        drawerLayout = findViewById(R.id.drawer_layout);
        actionBarDrawerToggle = new ActionBarDrawerToggle(this, drawerLayout, R.string.nav_open, R.string.nav_close);
        drawerLayout.addDrawerListener(actionBarDrawerToggle);
        actionBarDrawerToggle.syncState();
        getSupportActionBar().setDisplayHomeAsUpEnabled(true);
        transitionToFragment(new Home());

        NavigationView nav = findViewById(R.id.nav_menu);
        nav.setNavigationItemSelectedListener(item -> {
            Fragment fragment = null;
            switch(item.getItemId()) {
                case R.id.nav_home:
                    fragment = new Home();
                    break;

                case R.id.nav_input:
                    fragment = new Input();
                    break;

                case R.id.nav_setup:
                    fragment = new Setup();
                    break;

                case R.id.nav_settings:
                    //fragment = new Settings();
                    break;
            }
            transitionToFragment(fragment);
            drawerLayout.closeDrawer(Gravity.LEFT);
            return false;
        });

    }

    @Override
    public boolean onOptionsItemSelected(@NonNull MenuItem item) {
        if (actionBarDrawerToggle.onOptionsItemSelected(item)) {
            return true;
        } else {
            Fragment fragment = new ManualEntry();
            transitionToFragment(fragment);
        }
        return super.onOptionsItemSelected(item);
    }

    private void transitionToFragment(Fragment fragment) {
        getSupportFragmentManager().beginTransaction().replace(R.id.body_container, fragment).commit();
    }

    private void hideSystemBars() {
        WindowInsetsControllerCompat windowInsetsController =
                ViewCompat.getWindowInsetsController(getWindow().getDecorView());
        if (windowInsetsController == null) {
            return;
        }
        windowInsetsController.setSystemBarsBehavior(
                WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
        );
        windowInsetsController.hide(WindowInsetsCompat.Type.navigationBars());
    }

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        getMenuInflater().inflate(R.menu.options_menu, menu);
        return true;
    }
}