package com.sukhesh.scoutingapp;

import android.content.Context;
import android.content.SharedPreferences;
import android.content.res.Configuration;
import android.os.Bundle;

import androidx.fragment.app.Fragment;

import android.os.SystemClock;

import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.SeekBar;
import android.widget.TextView;
import android.widget.Toast;

import com.sukhesh.scoutingapp.fields.ClosedQuestion;
import com.sukhesh.scoutingapp.fields.FiniteInt;
import com.sukhesh.scoutingapp.fields.SliderValue;
import com.sukhesh.scoutingapp.fields.Timer;
import com.sukhesh.scoutingapp.storage.JSONStorage;

import java.util.ArrayList;

public class RapidReactInput extends Fragment {

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        View rootView;
        Configuration config = getResources().getConfiguration();
        if (config.smallestScreenWidthDp >= 600) {
            rootView = inflater.inflate(R.layout.fragment_rapid_react_dashboard_tablet, container, false);
        } else {
            rootView = inflater.inflate(R.layout.fragment_rapid_react_dashboard_phone, container, false);
        }
        SharedPreferences sp = requireContext().getSharedPreferences("matches", Context.MODE_PRIVATE);
        Log.d("quals", sp.getString("json", "NOT FOUND"));
        String matchName = sp.getString("currentMatch", "Q1");
        JSONStorage storage = new JSONStorage(sp);
        TextView title = rootView.findViewById(R.id.title_dashboard);
        String matchType = storage.getString(matchName, "matchType");
        switch (matchType) {
            case "Q":
                title.setText("Qualification " + storage.getInt(matchName,"matchNumber"));
                break;
            case "QF":
                title.setText("Quarter Final " + storage.getInt(matchName,"matchNumber"));
                break;
            case "SF":
                title.setText("Semi Final " + storage.getInt(matchName,"matchNumber"));
                break;
            case "F":
                title.setText("Final " + storage.getInt(matchName,"matchNumber"));
                break;
            case "EF":
                title.setText("EINSTEIN FINAL " + storage.getInt(matchName,"matchNumber"));
                break;
        }

        TextView teamNum = rootView.findViewById(R.id.heading_dashboard_teamNum);
        teamNum.setText(String.valueOf(storage.getInt(matchName,"teamNumber")));

        TextView teamColor = rootView.findViewById(R.id.heading_dashboard_teamColor);
        String robotAllianceInfo = storage.getString(matchName,"robotAllianceInfo");
        switch (robotAllianceInfo.charAt(0)) {
            case 'B':
                teamColor.setText("Blue " + robotAllianceInfo.charAt(1));
                break;
            case 'R':
                teamColor.setText("Red " + robotAllianceInfo.charAt(1));
        }

        ArrayList<View> rawViews = new ArrayList<>();
        rootView.findViewsWithText(rawViews, "FiniteInt", View.FIND_VIEWS_WITH_CONTENT_DESCRIPTION);
        ArrayList<FiniteInt> finiteInts = FiniteInt.generateArrayListFromViews(rawViews);

        for(FiniteInt f: finiteInts) {
            f.updateValue(storage, matchName);
            f.plus.setOnClickListener(view -> {
                f.value++;
                f.tally.setText(String.valueOf(f.value));

                storage.add(matchName, f.name, f.value);
            });
            f.minus.setOnClickListener(view -> {
                if(f.value > 0) {
                    f.value--;
                    f.tally.setText(String.valueOf(f.value));
                    storage.add(matchName, f.name, f.value);
                } else {
                    Toast.makeText(getActivity(), "You cannot go below 0!", Toast.LENGTH_SHORT).show();
                }
            });
        }

        rawViews.clear();
        rootView.findViewsWithText(rawViews, "ClosedQuestion", View.FIND_VIEWS_WITH_CONTENT_DESCRIPTION);
        ArrayList<ClosedQuestion> checkboxes = ClosedQuestion.generateArrayListFromViews(rawViews);
        for(ClosedQuestion c: checkboxes) {
            c.updateValue(storage, matchName);
            c.check.setOnClickListener(view -> {
                c.value = c.check.isChecked();
                storage.add(matchName, c.name, c.value);
            });
            c.text.setOnClickListener(view -> {
                boolean isChecked = c.check.isChecked();
                if(isChecked) {
                    c.check.setChecked(false);
                    storage.add(matchName, c.name, false);
                } else {
                    c.check.setChecked(true);
                    storage.add(matchName, c.name, true);
                }
            });
        }


        rawViews.clear();
        rootView.findViewsWithText(rawViews, "SliderValue", View.FIND_VIEWS_WITH_CONTENT_DESCRIPTION);
        ArrayList<SliderValue> sliderValues = SliderValue.generateArrayListFromViews(rawViews);
        for (SliderValue s: sliderValues) {
            s.updateValue(storage, matchName);
            s.slider.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener() {
                @Override
                public void onProgressChanged(SeekBar seekBar, int i, boolean b) {
                    s.value = i;
                    s.text.setText(s.defaultText + " " + i);
                    storage.add(matchName, s.name, s.value);
                }

                @Override
                public void onStartTrackingTouch(SeekBar seekBar) {

                }

                @Override
                public void onStopTrackingTouch(SeekBar seekBar) {

                }
            });
        }


        //Stopwatch
        rawViews.clear();
        rootView.findViewsWithText(rawViews, "Timer", View.FIND_VIEWS_WITH_CONTENT_DESCRIPTION);
        ArrayList<Timer> timers = Timer.generateArrayListFromViews(rawViews);
        for(Timer t: timers) {
            t.updateValue(storage, matchName);
            t.start.setOnClickListener(view -> {
                if(!t.running){
                    t.time.setBase(SystemClock.elapsedRealtime() - t.value);
                    t.time.start();
                    t.running = true;
                }
            });
            t.stop.setOnClickListener(view -> {
                if(t.running) {
                    t.time.stop();
                    t.value = SystemClock.elapsedRealtime() - t.time.getBase();
                    t.running = false;
                }
                storage.add(matchName, t.name, t.value);
            });
            t.reset.setOnClickListener(view -> {
                t.time.setBase(SystemClock.elapsedRealtime());
                t.value = 0;
            });
        }

        //Finish Button
        Button finish = rootView.findViewById(R.id.finish);
        finish.setOnClickListener(view -> getParentFragmentManager().beginTransaction().replace(R.id.body_container, new QRPage()).commit());
        return rootView;
    }
}
