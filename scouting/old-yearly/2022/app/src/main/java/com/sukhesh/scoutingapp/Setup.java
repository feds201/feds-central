package com.sukhesh.scoutingapp;

import android.content.Context;
import android.content.SharedPreferences;
import android.os.Bundle;

import androidx.fragment.app.Fragment;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.EditText;
import android.widget.Toast;

import com.sukhesh.scoutingapp.api.BlueAllianceAPI;

public class Setup extends Fragment {
    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        View setupView = inflater.inflate(R.layout.fragment_setup_phone, container, false);
        SharedPreferences sp = requireContext().getSharedPreferences("matches", Context.MODE_PRIVATE);
        EditText competitionCodeInput = setupView.findViewById(R.id.compcodeinput);
        EditText colorCodeInput = setupView.findViewById(R.id.alliancecolor);
        EditText tbaAuthInput = setupView.findViewById(R.id.tbhauthcode);
        Button submitButton = setupView.findViewById(R.id.submit);

        submitButton.setOnClickListener(view -> {
            SharedPreferences.Editor edit = sp.edit();
            edit.putString("json", "");
            edit.apply();
            if(tbaAuthInput.getText().toString().equals("ilovescouting22")) {
                if(!colorCodeInput.getText().toString().equals("")) {
                    BlueAllianceAPI.SendColorCodeToSharedPreferences(sp, colorCodeInput.getText().toString());
                }
                if(!competitionCodeInput.getText().toString().equals("")) {
                    BlueAllianceAPI.SendEventCodeToSharedPreferences(sp, competitionCodeInput.getText().toString());
                }
                Toast.makeText(getActivity(), "Submitted!", Toast.LENGTH_LONG).show();

                competitionCodeInput.setText("");
                colorCodeInput.setText("");
                tbaAuthInput.setText("");

                SharedPreferences.Editor editor = sp.edit();
                editor.putString("currentMatch", "Q1");
                editor.apply();
            } else {
                Toast.makeText(getActivity(), "Please enter the correct auth code.", Toast.LENGTH_SHORT).show();
            }
        });

        return setupView;
    }
}