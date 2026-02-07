package com.sukhesh.scoutingapp.fields;

import android.util.Log;
import android.view.View;
import android.widget.Button;
import android.widget.Chronometer;
import android.widget.TextView;

import com.sukhesh.scoutingapp.storage.JSONStorage;

import java.util.ArrayList;

public class Timer {
    public String name;

    public Chronometer time;
    public Button start;
    public Button stop;
    public Button reset;

    public boolean running;

    public long value;

    Timer(String name, Chronometer time, Button start, Button stop, Button reset) {
        this.name = name;
        this.time = time;
        this.start = start;
        this.stop = stop;
        this.reset = reset;

        this.value = 0;
    }

    public static ArrayList<Timer> generateArrayListFromViews(ArrayList<View> views) {
        // TODO: HECKA JANKY
        final int TIME = 0;
        final int START = 1;
        final int STOP = 2;
        final int RESET = 3;

        ArrayList<String> names = new ArrayList<>();
        ArrayList<View[]> intermediateViews = new ArrayList<>();

        ArrayList<Timer> timers = new ArrayList<>();
        String name;
        for(View v: views) {
            int indexIntoField = 0;
            if(v.getContentDescription().toString().split(" ").length == 2) {
                indexIntoField = TIME;
                // NOTE: for the CHRONOMETER as it uses the Content Description for its own thing, you need to name the id the same as the whole field name
                // ex: if the name for the whole field was "endgameTime" the Chronometer for the Timer field would have to have an id of "endgameTime" sorry :) - Zayn
                name = v.getResources().getResourceName(v.getId()).split("/")[1]; // Still pretty bad but acceptable in levels of badness
            } else {
                name = v.getContentDescription().toString().split(" ")[1];
                String component = v.getContentDescription().toString().split(" ")[2].toLowerCase();
                switch (component) {
                    case "start":
                        indexIntoField = START;
                        break;
                    case "stop":
                        indexIntoField = STOP;
                        break;
                    case "reset":
                        indexIntoField = RESET;
                        break;
                }
            }

            int indexInNames = names.indexOf(name);
            if(indexInNames == -1) {
                names.add(name);
                View[] field = new View[4];
                field[indexIntoField] = v;
                intermediateViews.add(field);
            } else {
                intermediateViews.get(indexInNames)[indexIntoField] = v;
            }
        }

        for(int i = 0; i < intermediateViews.size(); i++) {
            Timer f = new Timer(
                    names.get(i),
                    (Chronometer)intermediateViews.get(i)[TIME],
                    (Button)intermediateViews.get(i)[START],
                    (Button)intermediateViews.get(i)[STOP],
                    (Button)intermediateViews.get(i)[RESET]);
            timers.add(f);
        }

        return timers;

    }
    public void updateValue(JSONStorage js, String matchName) {
        this.value = js.getInt(matchName, this.name);
        long secs = this.value / 1000;
        int mins = (int)secs / 60;
        secs = secs % 60;

        if (mins < 10) {
            this.time.setText("0" + mins + ":" + secs);
        } else {
            this.time.setText(mins + ":" + secs);
        }

    }
}
