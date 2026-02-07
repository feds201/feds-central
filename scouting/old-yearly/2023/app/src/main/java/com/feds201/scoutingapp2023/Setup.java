package com.feds201.scoutingapp2023;

import android.content.Context;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.EditText;
import android.widget.Toast;

import androidx.fragment.app.Fragment;

import com.feds201.scoutingapp2023.api.BlueAllianceAPI;
import com.feds201.scoutingapp2023.sql.DatabaseUtilities;

import java.util.ArrayList;

//import com.sukhesh.scoutingapp.api.BlueAllianceAPI;

public class Setup extends Fragment {
    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        View setupView = inflater.inflate(R.layout.fragment_setup_tablet, container, false);
        SharedPreferences sp = requireContext().getSharedPreferences("matches", Context.MODE_PRIVATE);
        EditText competitionCodeInput = setupView.findViewById(R.id.compcodeinput);
        EditText colorCodeInput = (EditText) setupView.findViewById(R.id.alliancecolor);
        EditText tbaAuthInput = setupView.findViewById(R.id.tbhauthcode);
        Button submitButton = setupView.findViewById(R.id.submit);

        submitButton.setOnClickListener(view -> {
            String color = colorCodeInput.getText().toString();
            //Log.d("json", color);
            if(tbaAuthInput.getText().toString().equals("ilovescouting23")) {
                if(!competitionCodeInput.getText().toString().equals("") && !colorCodeInput.getText().toString().equals("")) {
                    new Thread(() -> {
                        String s = BlueAllianceAPI.RequestMatchesByEventCode(competitionCodeInput.getText().toString(), "5ED1uRm7sTzNCXRwuSyPUnFt3uFuDVpO0lZKFQplA2EjCOsqwSWNzQpqwTTRM2ba");

                        ArrayList<String[]> teamNumberMatchNumberMatchType = BlueAllianceAPI.TeamNumberMatchNumberMatchType(s, color);

                        DatabaseUtilities.DropAllMatches();
                        DatabaseUtilities.TeamNumberMatchNumberMatchTypeColorColorNumberToRow(teamNumberMatchNumberMatchType, color.contains("R") ? "Red" : "Blue", Integer.parseInt(color.substring(1)));

                    }).start();
                    Toast.makeText(getActivity(), "Submitted", Toast.LENGTH_LONG).show();
                } else {
                    Toast.makeText(getActivity(), "One of the two forms are empty", Toast.LENGTH_SHORT).show();
                }
            } else {
                Toast.makeText(getActivity(), "Please enter the correct auth code.", Toast.LENGTH_SHORT).show();
            }
        });

        return setupView;
    }
}