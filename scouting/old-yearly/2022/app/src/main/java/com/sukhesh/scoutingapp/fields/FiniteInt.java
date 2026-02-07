package com.sukhesh.scoutingapp.fields;

import android.view.View;
import android.widget.Button;
import android.widget.TextView;

import com.sukhesh.scoutingapp.storage.JSONStorage;

import java.util.ArrayList;

public class FiniteInt {
    public String name;
    public Button plus;
    public Button minus;
    public TextView tally;

    public int value;

    FiniteInt(String name, Button plus, Button minus, TextView tally) {
        this.name = name;
        this.plus = plus;
        this.minus = minus;
        this.tally = tally;

        this.value = Integer.parseInt(tally.getText().toString());
    }

    public static ArrayList<FiniteInt> generateArrayListFromViews(ArrayList<View> views) {
        // TODO: HECKA JANKY
        final int PLUS = 0;
        final int MINUS = 1;
        final int TALLY = 2;

        ArrayList<String> names = new ArrayList<>();
        ArrayList<View[]> intermediateViews = new ArrayList<>();

        ArrayList<FiniteInt> finiteInts = new ArrayList<>();
        for(View v: views) {
            String name = v.getContentDescription().toString().split(" ")[1];
            String component = v.getContentDescription().toString().split(" ")[2].toLowerCase();
            int indexIntoField = 0;

            switch (component) {
                case "plus":
                    indexIntoField = PLUS;
                    break;
                case "minus":
                    indexIntoField = MINUS;
                    break;
                case "tally":
                    indexIntoField = TALLY;
                    break;
            }

            int indexInNames = names.indexOf(name);
            if(indexInNames == -1) {
                names.add(name);
                View[] field = new View[3];
                field[indexIntoField] = v;
                intermediateViews.add(field);
            } else {
                intermediateViews.get(indexInNames)[indexIntoField] = v;
            }
        }

        for(int i = 0; i < intermediateViews.size(); i++) {
            FiniteInt f = new FiniteInt(
                    names.get(i),
                    (Button)intermediateViews.get(i)[PLUS],
                    (Button)intermediateViews.get(i)[MINUS],
                    (TextView) intermediateViews.get(i)[TALLY]);
            finiteInts.add(f);
        }

        return finiteInts;
    }

    public void updateValue(JSONStorage js, String matchName) {
        this.value = js.getInt(matchName, this.name);
        this.tally.setText(String.valueOf(this.value));
    }
}
