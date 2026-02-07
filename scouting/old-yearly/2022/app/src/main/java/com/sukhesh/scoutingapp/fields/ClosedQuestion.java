package com.sukhesh.scoutingapp.fields;

import android.view.View;
import android.widget.CheckBox;
import android.widget.SeekBar;
import android.widget.TextView;

import com.sukhesh.scoutingapp.storage.JSONStorage;

import java.util.ArrayList;

public class ClosedQuestion {
    public final String name;
    public final CheckBox check;
    public final TextView text;

    public boolean value;

    ClosedQuestion(String name, CheckBox check, TextView text) {
        this.name = name;
        this.check = check;
        this.text = text;
        this.value = false;
    }

    public static ArrayList<ClosedQuestion> generateArrayListFromViews(ArrayList<View> views) {
        // TODO: HECKA JANKY
        final int CHECK = 0;
        final int TEXT = 1;

        ArrayList<String> names = new ArrayList<>();
        ArrayList<View[]> intermediateViews = new ArrayList<>();

        ArrayList<ClosedQuestion> checkboxes = new ArrayList<>();
        for(View v: views) {
            String name = v.getContentDescription().toString().split(" ")[1];
            String component = v.getContentDescription().toString().split(" ")[2].toLowerCase();
            int indexIntoField = 0;

            switch (component) {
                case "check":
                    indexIntoField = CHECK;
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
            ClosedQuestion f = new ClosedQuestion(
                    names.get(i),
                    (CheckBox) intermediateViews.get(i)[CHECK],
                    (TextView) intermediateViews.get(i)[TEXT]);
            checkboxes.add(f);
        }

        return checkboxes;
    }

    public void updateValue(JSONStorage js, String matchName) {
        this.value = js.getBoolean(matchName, this.name);
        if(this.value) {
            this.check.toggle();
        }
    }
}
