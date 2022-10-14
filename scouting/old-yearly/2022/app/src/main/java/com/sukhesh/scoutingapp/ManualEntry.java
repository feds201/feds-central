package com.sukhesh.scoutingapp;

import android.os.Bundle;

import androidx.fragment.app.Fragment;

import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.EditText;
import android.widget.TextView;

import java.util.ArrayList;

public class ManualEntry extends Fragment {
    ArrayList<String> qualArr = new ArrayList<String>();
    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        View rootView = inflater.inflate(R.layout.fragment_manual_entry, container, false);
        Button create = rootView.findViewById(R.id.newButton);
        Button append = rootView.findViewById(R.id.appendButton);
        EditText input = rootView.findViewById(R.id.input);

        append.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                String x = String.valueOf(input);
                String qual = x.substring( 0, x.indexOf(","));
                String teamNum = x.substring(x.indexOf(",") + 2, x.indexOf(",", x.indexOf(",") + 1));
                String y = x.substring(x.indexOf(",", x.indexOf(",") + 2), x.length());
                String color = y.substring(2, y.length());
                qualArr.add(qual);
            }
        });
        return rootView;
    }

    public ArrayList getList() {
        return qualArr;
    }
}