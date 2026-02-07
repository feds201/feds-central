package com.sukhesh.scoutingapp.fields;

import android.view.View;
import android.widget.SeekBar;
import android.widget.TextView;

import com.sukhesh.scoutingapp.storage.JSONStorage;

import java.util.ArrayList;

public class SliderValue {
    public String name;
    public SeekBar slider;
    public TextView text;
    public String defaultText;

    public int value;

    SliderValue(String name, SeekBar slider, TextView text) {
        this.name = name;
        this.slider = slider;
        this.text = text;

        this.defaultText = this.text.getText().toString();
        this.value = 0;
    }

    public static ArrayList<SliderValue> generateArrayListFromViews(ArrayList<View> views) {
        // TODO: HECKA JANKY
        final int SLIDER = 0;
        final int TEXT = 1;

        ArrayList<String> names = new ArrayList<>();
        ArrayList<View[]> intermediateViews = new ArrayList<>();

        ArrayList<SliderValue> finiteInts = new ArrayList<>();
        for(View v: views) {
            String name = v.getContentDescription().toString().split(" ")[1];
            String component = v.getContentDescription().toString().split(" ")[2].toLowerCase();
            int indexIntoField = 0;

            switch (component) {
                case "slider":
                    indexIntoField = SLIDER;
                    break;
                case "text":
                    indexIntoField = TEXT;
                    break;
            }

            int indexInNames = names.indexOf(name);
            if(indexInNames == -1) {
                names.add(name);
                View[] field = new View[2];
                field[indexIntoField] = v;
                intermediateViews.add(field);
            } else {
                intermediateViews.get(indexInNames)[indexIntoField] = v;
            }
        }

        for(int i = 0; i < intermediateViews.size(); i++) {
            SliderValue f = new SliderValue(
                    names.get(i),
                    (SeekBar)intermediateViews.get(i)[SLIDER],
                    (TextView) intermediateViews.get(i)[TEXT]);
            finiteInts.add(f);
        }

        return finiteInts;
    }

    public void updateValue(JSONStorage js, String matchName) {
        this.value = js.getInt(matchName, this.name);
        this.text.setText(defaultText + " " + String.valueOf(this.value));
    }
}
