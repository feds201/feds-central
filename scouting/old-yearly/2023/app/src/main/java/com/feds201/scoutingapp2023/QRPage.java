package com.feds201.scoutingapp2023;

import android.content.Context;
import android.content.SharedPreferences;
import android.graphics.Bitmap;
import android.os.Bundle;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;

import androidx.fragment.app.Fragment;

import com.google.zxing.BarcodeFormat;
import com.google.zxing.MultiFormatWriter;
import com.google.zxing.WriterException;
import com.google.zxing.common.BitMatrix;
import com.journeyapps.barcodescanner.BarcodeEncoder;

//import com.google.zxing.BarcodeFormat;
//import com.google.zxing.MultiFormatWriter;
//import com.google.zxing.WriterException;
//import com.google.zxing.common.BitMatrix;
//import com.journeyapps.barcodescanner.BarcodeEncoder;

public class QRPage extends Fragment {
    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        /* QR Variables needed:
         * Auton -
         * How many on top(cubes / cones), middle(cubes / cones), bottom(cubes / cones) - 6 data sets
         * How many total cubes / cones - 2 data sets
         * Mobility checkbox - 1 data set
         * How many pieces the team dropped during auton - 1 data set
         * how many pieces total did the team acquire? - 1 data set
         * Charge station status - 1 data set
         * TOTAL: 12 data sets from auton
         *
         * Teleop -
         * How many on top(cubes / cones), middle(cubes / cones), bottom(cubes / cones) - 6 data sets
         * How many total cubes / cones - 2 data sets
         * What was their strategy (What are they good at) Feeding? Placing? or Both? - 1 data set
         * Coopertition checkbox - 1 data set
         * Were they playing defense? - (For this, have a dropdown for the person to select which team they played on the other alliance) - 1 data set
         * TOTAL: 11 data sets from teleop
         *
         * Endgame -
         * Charge station status - 1 data set
         * How many links did the alliance make? - 1 data set
         * Did the robot get disabled? - 1 data set
         * TOTAL: 3 data sets from endgame
         *
         * GRAND TOTAL: 27 (26 from above + 1 for tablet id)
         *
         * QR FORMAT -
         * The tablet id goes on the first line (is it tablet 01,02, etc.)
         * We want to make a small gui in the python qr reader where it detects which tablets have been scanned and indicates it
         * thats what we need the tablet id
         * everything else goes below this line like the data
         */
//
        View rootView = inflater.inflate(R.layout.fragment_qr_tablet, container, false);

        String content = Input.currentMatch.toQRCodeString();

        ImageView ivOutput = rootView.findViewById(R.id.iv_output);
        MultiFormatWriter writer = new MultiFormatWriter();
        try {
            BitMatrix matrix = writer.encode(content, BarcodeFormat.QR_CODE, 800, 800);
            BarcodeEncoder encoder = new BarcodeEncoder();
            Bitmap bitmap = encoder.createBitmap(matrix);
            ivOutput.setImageBitmap(bitmap);
        } catch (WriterException e) {
            e.printStackTrace();
        }

        //Log.d("match", Input.currentMatch.toString());

        return rootView;
    }
}