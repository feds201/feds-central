package com.feds201.scoutingapp2023.component;

import android.widget.Button;
import android.widget.TextView;

public class Tally implements Component {
    public final Button plus, minus;
    public final TextView text;
    public Tally(Button plus, Button minus, TextView text) {
        this.plus = plus;
        this.minus = minus;
        this.text = text;
    }
}
