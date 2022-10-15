package com.sukhesh.scoutingapp;

import android.content.Context;
import android.os.Bundle;

import androidx.fragment.app.Fragment;

import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.EditText;
import android.widget.TextView;
import android.widget.Toast;

import com.sukhesh.scoutingapp.storage.JSONStorage;

import org.json.JSONException;

import java.util.ArrayList;
import java.util.regex.PatternSyntaxException;

public class ManualEntry extends Fragment {
    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        View rootView = inflater.inflate(R.layout.fragment_manual_entry, container, false);
        Button create = rootView.findViewById(R.id.newButton);
        Button append = rootView.findViewById(R.id.appendButton);
        EditText input = rootView.findViewById(R.id.input);

        create.setOnClickListener(view -> {
            String rawString = input.getText().toString();
            if(rawString.length() > 0) {
                try
                {
                    String[] strs = rawString.split("\n");
                    if (JSONStorage.validateJSONStrings(strs)) {
                        try {
                            JSONStorage.addMatches(requireContext().getSharedPreferences("matches", Context.MODE_PRIVATE), strs);
                        } catch (JSONException e) {
                            Toast.makeText(getActivity(), "BRUHHHHHH", Toast.LENGTH_SHORT).show();
                        }
                    }
                    else
                    {
                        Toast.makeText(getActivity(), "There was an error: please fix the order/syntax of your line.", Toast.LENGTH_SHORT).show();
                    }
                }
                catch (PatternSyntaxException e) {
                    String strs[] = new String[1];
                    strs[0] = rawString;
                    if (JSONStorage.validateJSONStrings(strs)) {
                        try {
                            JSONStorage.addMatches(requireContext().getSharedPreferences("matches", Context.MODE_PRIVATE), strs);
                        } catch (JSONException err) {
                            Toast.makeText(getActivity(), "BRUHHHHHH", Toast.LENGTH_SHORT).show();
                        }
                    }
                    else
                    {
                        Toast.makeText(getActivity(), "There was an error: please fix the order/syntax of your line.", Toast.LENGTH_SHORT).show();
                    }
                }

            } else {
                Toast.makeText(getActivity(), "Please input something in the right format!", Toast.LENGTH_SHORT).show();
            }
        });
        append.setOnClickListener(view -> {
            String rawString = input.getText().toString();
            if(rawString.length() > 0) {
                try
                {
                    String[] strs = rawString.split("\n");
                    if (JSONStorage.validateJSONStrings(strs)) {
                        try {
                            JSONStorage.appendMatches(requireContext().getSharedPreferences("matches", Context.MODE_PRIVATE), strs);
                        } catch (JSONException e) {
                            Toast.makeText(getActivity(), "BRUHHHHHH", Toast.LENGTH_SHORT).show();
                        }
                    }
                    else
                    {
                        Toast.makeText(getActivity(), "There was an error: please fix the order/syntax of your line.", Toast.LENGTH_SHORT).show();
                    }
                }
                catch (PatternSyntaxException e) {
                    String strs[] = new String[1];
                    strs[0] = rawString;
                    if (JSONStorage.validateJSONStrings(strs)) {
                        try {
                            JSONStorage.appendMatches(requireContext().getSharedPreferences("matches", Context.MODE_PRIVATE), strs);
                        } catch (JSONException err) {
                            Toast.makeText(getActivity(), "BRUHHHHHH", Toast.LENGTH_SHORT).show();
                        }
                    }
                    else
                    {
                        Toast.makeText(getActivity(), "There was an error: please fix the order/syntax of your line.", Toast.LENGTH_SHORT).show();
                    }
                }
            } else {
                Toast.makeText(getActivity(), "Please input something in the right format!", Toast.LENGTH_SHORT).show();
            }
        });
        return rootView;
    }
}