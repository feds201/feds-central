package com.sukhesh.scoutingapp;

import android.content.Context;
import android.content.SharedPreferences;
import android.os.Bundle;

import androidx.core.util.SizeFCompat;
import androidx.fragment.app.Fragment;

import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.EditText;

import com.sukhesh.scoutingapp.api.BlueAllianceAPI;

public class Setup extends Fragment {
    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        View setupView = inflater.inflate(R.layout.fragment_setup_phone, container, false);
        SharedPreferences sp = requireContext().getSharedPreferences("matches", Context.MODE_PRIVATE);
        EditText competitionCodeInput = setupView.findViewById(R.id.compcodeinput);
//        EditText TBAAuthCodeInput = setupView.findViewById(R.id.tbhauthcode);
        EditText colorCodeInput = setupView.findViewById(R.id.alliancecolor);
        Button submitButton = setupView.findViewById(R.id.submit);

        submitButton.setOnClickListener(view -> {
            SharedPreferences.Editor edit = sp.edit();
            edit.putString("json", "");
            edit.apply();
            if(!colorCodeInput.getText().toString().equals("")) {
                BlueAllianceAPI.SendColorCodeToSharedPreferences(sp, colorCodeInput.getText().toString());
            }
            if(!competitionCodeInput.getText().toString().equals("")) {
                BlueAllianceAPI.SendEventCodeToSharedPreferences(sp, competitionCodeInput.getText().toString());
            }
//            String compCode = competitionCodeInput.getText().toString();
//            String TBAAuth = TBAAuthCodeInput.getText().toString();
//            String colorCode = colorCodeInput.getText().toString();
//
//            int lenCompCode = compCode.length();
//            int lenTBACode = TBAAuth.length();
//            int lenColorCode = colorCode.length();
//
//            if(lenCompCode >= 4 && lenCompCode <= 13 && lenColorCode == 2) {
//                SharedPreferences sp = requireContext().getSharedPreferences("matches", Context.MODE_PRIVATE);
//                SharedPreferences.Editor edit = sp.edit();
//                edit.putString("eventCode", compCode);
//                edit.putString("colorCode", colorCode);
//                edit.putString("rawMatches", "");
//                edit.apply();
//            }
        });

        return setupView;
    }
}