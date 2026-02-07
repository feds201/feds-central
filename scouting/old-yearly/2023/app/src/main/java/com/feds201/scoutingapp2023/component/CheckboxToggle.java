package com.feds201.scoutingapp2023.component;

import android.view.View;
import android.widget.CheckBox;
import android.widget.TextView;

public class CheckboxToggle implements Component {
    private CheckBox checkBox;
    private String idCheckBoxString;
    private String idLabelString;
    private TextView label;
    public CheckboxToggle(int checkboxId, int labelId, View view, String idCheckBoxString, String idLabelString) {
        this.checkBox = view.findViewById(checkboxId);
        this.label = view.findViewById(labelId);
        this.idCheckBoxString = idCheckBoxString;
        this.idLabelString = idLabelString;
    }

    public String toString() {
        return "CheckBox: " + idCheckBoxString + "\tLabel: " + idLabelString;
    }
}
