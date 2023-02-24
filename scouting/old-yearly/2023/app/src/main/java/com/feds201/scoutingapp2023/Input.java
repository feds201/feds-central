package com.feds201.scoutingapp2023;

import android.content.res.Resources;
import android.graphics.drawable.AdaptiveIconDrawable;
import android.graphics.drawable.Drawable;
import android.os.Bundle;

import androidx.core.content.res.ResourcesCompat;
import androidx.fragment.app.Fragment;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.CheckBox;
import android.widget.ImageButton;
import android.widget.ImageView;
import android.widget.TextView;


public class Input extends Fragment {
    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        View inputView = inflater.inflate(R.layout.fragment_input, container, false);
        //READ QR PAGE BEFORE WORKING!!!!!!!!!!!!!!!!!!!!!!!!!

        //For the grid (Make button class instead of this bs)
        //This example is with the top middle button
        //Im assuming in the qr cone means 0, cube means 1, nothing means 2, or something like that
        //Also use some variable to keep track of how many cubes / cones on each row

        //EVERYTHING ON AUTON PAGE
        ImageView autongrid = inputView.findViewById(R.id.auton_grid);
        ImageButton autonbutton1 = inputView.findViewById(R.id.autonbutton1);
        ImageButton autonbutton2 = inputView.findViewById(R.id.autonbutton2);
        ImageButton autonbutton3 = inputView.findViewById(R.id.autonbutton3);
        ImageButton autonbutton4 = inputView.findViewById(R.id.autonbutton4);
        ImageButton autonbutton5 = inputView.findViewById(R.id.autonbutton5);
        ImageButton autonbutton6 = inputView.findViewById(R.id.autonbutton6);
        ImageButton autonbutton7 = inputView.findViewById(R.id.autonbutton7);
        ImageButton autonbutton8 = inputView.findViewById(R.id.autonbutton8);
        ImageButton autonbutton9 = inputView.findViewById(R.id.autonbutton9);
        ImageButton autonbutton10 = inputView.findViewById(R.id.autonbutton10);
        ImageButton autonbutton11 = inputView.findViewById(R.id.autonbutton11);
        ImageButton autonbutton12 = inputView.findViewById(R.id.autonbutton12);
        ImageButton autonbutton13 = inputView.findViewById(R.id.autonbutton13);
        ImageButton autonbutton14 = inputView.findViewById(R.id.autonbutton14);
        ImageButton autonbutton15 = inputView.findViewById(R.id.autonbutton15);
        ImageButton autonbutton16 = inputView.findViewById(R.id.autonbutton16);
        ImageButton autonbutton17 = inputView.findViewById(R.id.autonbutton17);
        ImageButton autonbutton18 = inputView.findViewById(R.id.autonbutton18);
        ImageButton autonbutton19 = inputView.findViewById(R.id.autonbutton19);
        ImageButton autonbutton20 = inputView.findViewById(R.id.autonbutton20);
        ImageButton autonbutton21 = inputView.findViewById(R.id.autonbutton21);
        ImageButton autonbutton22 = inputView.findViewById(R.id.autonbutton22);
        ImageButton autonbutton23 = inputView.findViewById(R.id.autonbutton23);
        ImageButton autonbutton24 = inputView.findViewById(R.id.autonbutton24);
        ImageButton autonbutton25 = inputView.findViewById(R.id.autonbutton25);
        ImageButton autonbutton26 = inputView.findViewById(R.id.autonbutton26);
        ImageButton autonbutton27 = inputView.findViewById(R.id.autonbutton27);
        CheckBox autonmobilityCheckbox = inputView.findViewById(R.id.auton_mobility);
        TextView autonMobilityTitle = inputView.findViewById(R.id.auton_textView);
        TextView autonDroppedTitle = inputView.findViewById(R.id.auton_textView2);
        Button autonMinButton = inputView.findViewById(R.id.auton_button_minus);
        Button autonMinButton2 = inputView.findViewById(R.id.auton_button_minus2);
        TextView autonTally = inputView.findViewById(R.id.auton_tally);
        TextView autonTally2 = inputView.findViewById(R.id.auton_tally2);
        Button autonPlusButton = inputView.findViewById(R.id.auton_button_plus);
        Button autonPlusButton2 = inputView.findViewById(R.id.auton_button_plus2);
        TextView autonAcquiredTitle = inputView.findViewById(R.id.auton_textView3);
        ImageButton autonGreen = inputView.findViewById(R.id.auton_green);
        ImageButton autonYellow = inputView.findViewById(R.id.auton_yellow);
        ImageButton autonRed = inputView.findViewById(R.id.auton_red);
        TextView autonChargedStationTitle = inputView.findViewById(R.id.auton_textView4);

        //TAB SYSTEM
        ImageButton autontab = inputView.findViewById(R.id.autontab);
        ImageButton teleoptab = inputView.findViewById(R.id.teleoptab);
        ImageButton endgametab = inputView.findViewById(R.id.endgametab);

        //EVERYTHING ON TELEOP PAGE
        ImageView teleopgrid = inputView.findViewById(R.id.teleop_grid);
        ImageButton teleopbutton1 = inputView.findViewById(R.id.teleopbutton1);
        ImageButton teleopbutton2 = inputView.findViewById(R.id.teleopbutton2);
        ImageButton teleopbutton3 = inputView.findViewById(R.id.teleopbutton3);
        ImageButton teleopbutton4 = inputView.findViewById(R.id.teleopbutton4);
        ImageButton teleopbutton5 = inputView.findViewById(R.id.teleopbutton5);
        ImageButton teleopbutton6 = inputView.findViewById(R.id.teleopbutton6);
        ImageButton teleopbutton7 = inputView.findViewById(R.id.teleopbutton7);
        ImageButton teleopbutton8 = inputView.findViewById(R.id.teleopbutton8);
        ImageButton teleopbutton9 = inputView.findViewById(R.id.teleopbutton9);
        ImageButton teleopbutton10 = inputView.findViewById(R.id.teleopbutton10);
        ImageButton teleopbutton11 = inputView.findViewById(R.id.teleopbutton11);
        ImageButton teleopbutton12 = inputView.findViewById(R.id.teleopbutton12);
        ImageButton teleopbutton13 = inputView.findViewById(R.id.teleopbutton13);
        ImageButton teleopbutton14 = inputView.findViewById(R.id.teleopbutton14);
        ImageButton teleopbutton15 = inputView.findViewById(R.id.teleopbutton15);
        ImageButton teleopbutton16 = inputView.findViewById(R.id.teleopbutton16);
        ImageButton teleopbutton17 = inputView.findViewById(R.id.teleopbutton17);
        ImageButton teleopbutton18 = inputView.findViewById(R.id.teleopbutton18);
        ImageButton teleopbutton19 = inputView.findViewById(R.id.teleopbutton19);
        ImageButton teleopbutton20 = inputView.findViewById(R.id.teleopbutton20);
        ImageButton teleopbutton21 = inputView.findViewById(R.id.teleopbutton21);
        ImageButton teleopbutton22 = inputView.findViewById(R.id.teleopbutton22);
        ImageButton teleopbutton23 = inputView.findViewById(R.id.teleopbutton23);
        ImageButton teleopbutton24 = inputView.findViewById(R.id.teleopbutton24);
        ImageButton teleopbutton25 = inputView.findViewById(R.id.teleopbutton25);
        ImageButton teleopbutton26 = inputView.findViewById(R.id.teleopbutton26);
        ImageButton teleopbutton27 = inputView.findViewById(R.id.teleopbutton27);

        //EVERYTHING ON ENDGAME PAGE
        Button finish = inputView.findViewById(R.id.endgame_finish);

        //STUFF THAT SHOULD BE HIDDEN WHILE APP IS ON START
        finish.setVisibility(View.GONE);
        teleopgrid.setVisibility(View.GONE);
        teleopbutton1.setVisibility(View.GONE);
        teleopbutton2.setVisibility(View.GONE);
        teleopbutton3.setVisibility(View.GONE);
        teleopbutton4.setVisibility(View.GONE);
        teleopbutton5.setVisibility(View.GONE);
        teleopbutton6.setVisibility(View.GONE);
        teleopbutton7.setVisibility(View.GONE);
        teleopbutton8.setVisibility(View.GONE);
        teleopbutton9.setVisibility(View.GONE);
        teleopbutton10.setVisibility(View.GONE);
        teleopbutton11.setVisibility(View.GONE);
        teleopbutton12.setVisibility(View.GONE);
        teleopbutton13.setVisibility(View.GONE);
        teleopbutton14.setVisibility(View.GONE);
        teleopbutton15.setVisibility(View.GONE);
        teleopbutton16.setVisibility(View.GONE);
        teleopbutton17.setVisibility(View.GONE);
        teleopbutton18.setVisibility(View.GONE);
        teleopbutton19.setVisibility(View.GONE);
        teleopbutton20.setVisibility(View.GONE);
        teleopbutton21.setVisibility(View.GONE);
        teleopbutton22.setVisibility(View.GONE);
        teleopbutton23.setVisibility(View.GONE);
        teleopbutton24.setVisibility(View.GONE);
        teleopbutton25.setVisibility(View.GONE);
        teleopbutton26.setVisibility(View.GONE);
        teleopbutton27.setVisibility(View.GONE);

        //TAB SWITCHING
        autontab.setOnClickListener(view -> {
            autontab.setImageResource(R.drawable.autontab);
            teleoptab.setImageResource(R.drawable.teleoptabtrans);
            endgametab.setImageResource(R.drawable.endgametabtrans);
            autongrid.setVisibility(View.VISIBLE);
            autonbutton1.setVisibility(View.VISIBLE);
            autonbutton2.setVisibility(View.VISIBLE);
            autonbutton3.setVisibility(View.VISIBLE);
            autonbutton4.setVisibility(View.VISIBLE);
            autonbutton5.setVisibility(View.VISIBLE);
            autonbutton6.setVisibility(View.VISIBLE);
            autonbutton7.setVisibility(View.VISIBLE);
            autonbutton8.setVisibility(View.VISIBLE);
            autonbutton9.setVisibility(View.VISIBLE);
            autonbutton10.setVisibility(View.VISIBLE);
            autonbutton11.setVisibility(View.VISIBLE);
            autonbutton12.setVisibility(View.VISIBLE);
            autonbutton13.setVisibility(View.VISIBLE);
            autonbutton14.setVisibility(View.VISIBLE);
            autonbutton15.setVisibility(View.VISIBLE);
            autonbutton16.setVisibility(View.VISIBLE);
            autonbutton17.setVisibility(View.VISIBLE);
            autonbutton18.setVisibility(View.VISIBLE);
            autonbutton19.setVisibility(View.VISIBLE);
            autonbutton20.setVisibility(View.VISIBLE);
            autonbutton21.setVisibility(View.VISIBLE);
            autonbutton22.setVisibility(View.VISIBLE);
            autonbutton23.setVisibility(View.VISIBLE);
            autonbutton24.setVisibility(View.VISIBLE);
            autonbutton25.setVisibility(View.VISIBLE);
            autonbutton26.setVisibility(View.VISIBLE);
            autonbutton27.setVisibility(View.VISIBLE);
            autonmobilityCheckbox.setVisibility(View.VISIBLE);
            autonMobilityTitle.setVisibility(View.VISIBLE);
            autonDroppedTitle.setVisibility(View.VISIBLE);
            autonMinButton.setVisibility(View.VISIBLE);
            autonMinButton2.setVisibility(View.VISIBLE);
            autonTally.setVisibility(View.VISIBLE);
            autonTally2.setVisibility(View.VISIBLE);
            autonPlusButton.setVisibility(View.VISIBLE);
            autonPlusButton2.setVisibility(View.VISIBLE);
            autonAcquiredTitle.setVisibility(View.VISIBLE);
            autonGreen.setVisibility(View.VISIBLE);
            autonYellow.setVisibility(View.VISIBLE);
            autonRed.setVisibility(View.VISIBLE);
            autonChargedStationTitle.setVisibility(View.VISIBLE);

            teleopgrid.setVisibility(View.GONE);
            teleopbutton1.setVisibility(View.GONE);
            teleopbutton2.setVisibility(View.GONE);
            teleopbutton3.setVisibility(View.GONE);
            teleopbutton4.setVisibility(View.GONE);
            teleopbutton5.setVisibility(View.GONE);
            teleopbutton6.setVisibility(View.GONE);
            teleopbutton7.setVisibility(View.GONE);
            teleopbutton8.setVisibility(View.GONE);
            teleopbutton9.setVisibility(View.GONE);
            teleopbutton10.setVisibility(View.GONE);
            teleopbutton11.setVisibility(View.GONE);
            teleopbutton12.setVisibility(View.GONE);
            teleopbutton13.setVisibility(View.GONE);
            teleopbutton14.setVisibility(View.GONE);
            teleopbutton15.setVisibility(View.GONE);
            teleopbutton16.setVisibility(View.GONE);
            teleopbutton17.setVisibility(View.GONE);
            teleopbutton18.setVisibility(View.GONE);
            teleopbutton19.setVisibility(View.GONE);
            teleopbutton20.setVisibility(View.GONE);
            teleopbutton21.setVisibility(View.GONE);
            teleopbutton22.setVisibility(View.GONE);
            teleopbutton23.setVisibility(View.GONE);
            teleopbutton24.setVisibility(View.GONE);
            teleopbutton25.setVisibility(View.GONE);
            teleopbutton26.setVisibility(View.GONE);
            teleopbutton27.setVisibility(View.GONE);

            finish.setVisibility(View.GONE);
        });
        teleoptab.setOnClickListener(view -> {
            autontab.setImageResource(R.drawable.autontabtrans);
            teleoptab.setImageResource(R.drawable.teleoptab);
            endgametab.setImageResource(R.drawable.endgametabtrans);
            autongrid.setVisibility(View.GONE);
            autonbutton1.setVisibility(View.GONE);
            autonbutton2.setVisibility(View.GONE);
            autonbutton3.setVisibility(View.GONE);
            autonbutton4.setVisibility(View.GONE);
            autonbutton5.setVisibility(View.GONE);
            autonbutton6.setVisibility(View.GONE);
            autonbutton7.setVisibility(View.GONE);
            autonbutton8.setVisibility(View.GONE);
            autonbutton9.setVisibility(View.GONE);
            autonbutton10.setVisibility(View.GONE);
            autonbutton11.setVisibility(View.GONE);
            autonbutton12.setVisibility(View.GONE);
            autonbutton13.setVisibility(View.GONE);
            autonbutton14.setVisibility(View.GONE);
            autonbutton15.setVisibility(View.GONE);
            autonbutton16.setVisibility(View.GONE);
            autonbutton17.setVisibility(View.GONE);
            autonbutton18.setVisibility(View.GONE);
            autonbutton19.setVisibility(View.GONE);
            autonbutton20.setVisibility(View.GONE);
            autonbutton21.setVisibility(View.GONE);
            autonbutton22.setVisibility(View.GONE);
            autonbutton23.setVisibility(View.GONE);
            autonbutton24.setVisibility(View.GONE);
            autonbutton25.setVisibility(View.GONE);
            autonbutton26.setVisibility(View.GONE);
            autonbutton27.setVisibility(View.GONE);
            autonmobilityCheckbox.setVisibility(View.GONE);
            autonMobilityTitle.setVisibility(View.GONE);
            autonDroppedTitle.setVisibility(View.GONE);
            autonMinButton.setVisibility(View.GONE);
            autonMinButton2.setVisibility(View.GONE);
            autonTally.setVisibility(View.GONE);
            autonTally2.setVisibility(View.GONE);
            autonPlusButton.setVisibility(View.GONE);
            autonPlusButton2.setVisibility(View.GONE);
            autonAcquiredTitle.setVisibility(View.GONE);
            autonGreen.setVisibility(View.GONE);
            autonYellow.setVisibility(View.GONE);
            autonRed.setVisibility(View.GONE);
            autonChargedStationTitle.setVisibility(View.GONE);

            teleopgrid.setVisibility(View.VISIBLE);
            teleopbutton1.setVisibility(View.VISIBLE);
            teleopbutton2.setVisibility(View.VISIBLE);
            teleopbutton3.setVisibility(View.VISIBLE);
            teleopbutton4.setVisibility(View.VISIBLE);
            teleopbutton5.setVisibility(View.VISIBLE);
            teleopbutton6.setVisibility(View.VISIBLE);
            teleopbutton7.setVisibility(View.VISIBLE);
            teleopbutton8.setVisibility(View.VISIBLE);
            teleopbutton9.setVisibility(View.VISIBLE);
            teleopbutton10.setVisibility(View.VISIBLE);
            teleopbutton11.setVisibility(View.VISIBLE);
            teleopbutton12.setVisibility(View.VISIBLE);
            teleopbutton13.setVisibility(View.VISIBLE);
            teleopbutton14.setVisibility(View.VISIBLE);
            teleopbutton15.setVisibility(View.VISIBLE);
            teleopbutton16.setVisibility(View.VISIBLE);
            teleopbutton17.setVisibility(View.VISIBLE);
            teleopbutton18.setVisibility(View.VISIBLE);
            teleopbutton19.setVisibility(View.VISIBLE);
            teleopbutton20.setVisibility(View.VISIBLE);
            teleopbutton21.setVisibility(View.VISIBLE);
            teleopbutton22.setVisibility(View.VISIBLE);
            teleopbutton23.setVisibility(View.VISIBLE);
            teleopbutton24.setVisibility(View.VISIBLE);
            teleopbutton25.setVisibility(View.VISIBLE);
            teleopbutton26.setVisibility(View.VISIBLE);
            teleopbutton27.setVisibility(View.VISIBLE);

            finish.setVisibility(View.GONE);
        });
        endgametab.setOnClickListener(view -> {
            autontab.setImageResource(R.drawable.autontabtrans);
            teleoptab.setImageResource(R.drawable.teleoptabtrans);
            endgametab.setImageResource(R.drawable.endgametab);
            autongrid.setVisibility(View.GONE);
            autonbutton1.setVisibility(View.GONE);
            autonbutton2.setVisibility(View.GONE);
            autonbutton3.setVisibility(View.GONE);
            autonbutton4.setVisibility(View.GONE);
            autonbutton5.setVisibility(View.GONE);
            autonbutton6.setVisibility(View.GONE);
            autonbutton7.setVisibility(View.GONE);
            autonbutton8.setVisibility(View.GONE);
            autonbutton9.setVisibility(View.GONE);
            autonbutton10.setVisibility(View.GONE);
            autonbutton11.setVisibility(View.GONE);
            autonbutton12.setVisibility(View.GONE);
            autonbutton13.setVisibility(View.GONE);
            autonbutton14.setVisibility(View.GONE);
            autonbutton15.setVisibility(View.GONE);
            autonbutton16.setVisibility(View.GONE);
            autonbutton17.setVisibility(View.GONE);
            autonbutton18.setVisibility(View.GONE);
            autonbutton19.setVisibility(View.GONE);
            autonbutton20.setVisibility(View.GONE);
            autonbutton21.setVisibility(View.GONE);
            autonbutton22.setVisibility(View.GONE);
            autonbutton23.setVisibility(View.GONE);
            autonbutton24.setVisibility(View.GONE);
            autonbutton25.setVisibility(View.GONE);
            autonbutton26.setVisibility(View.GONE);
            autonbutton27.setVisibility(View.GONE);
            autonmobilityCheckbox.setVisibility(View.GONE);
            autonMobilityTitle.setVisibility(View.GONE);
            autonDroppedTitle.setVisibility(View.GONE);
            autonMinButton.setVisibility(View.GONE);
            autonMinButton2.setVisibility(View.GONE);
            autonTally.setVisibility(View.GONE);
            autonTally2.setVisibility(View.GONE);
            autonPlusButton.setVisibility(View.GONE);
            autonPlusButton2.setVisibility(View.GONE);
            autonAcquiredTitle.setVisibility(View.GONE);
            autonGreen.setVisibility(View.GONE);
            autonYellow.setVisibility(View.GONE);
            autonRed.setVisibility(View.GONE);
            autonChargedStationTitle.setVisibility(View.GONE);

            teleopgrid.setVisibility(View.GONE);
            teleopbutton1.setVisibility(View.GONE);
            teleopbutton2.setVisibility(View.GONE);
            teleopbutton3.setVisibility(View.GONE);
            teleopbutton4.setVisibility(View.GONE);
            teleopbutton5.setVisibility(View.GONE);
            teleopbutton6.setVisibility(View.GONE);
            teleopbutton7.setVisibility(View.GONE);
            teleopbutton8.setVisibility(View.GONE);
            teleopbutton9.setVisibility(View.GONE);
            teleopbutton10.setVisibility(View.GONE);
            teleopbutton11.setVisibility(View.GONE);
            teleopbutton12.setVisibility(View.GONE);
            teleopbutton13.setVisibility(View.GONE);
            teleopbutton14.setVisibility(View.GONE);
            teleopbutton15.setVisibility(View.GONE);
            teleopbutton16.setVisibility(View.GONE);
            teleopbutton17.setVisibility(View.GONE);
            teleopbutton18.setVisibility(View.GONE);
            teleopbutton19.setVisibility(View.GONE);
            teleopbutton20.setVisibility(View.GONE);
            teleopbutton21.setVisibility(View.GONE);
            teleopbutton22.setVisibility(View.GONE);
            teleopbutton23.setVisibility(View.GONE);
            teleopbutton24.setVisibility(View.GONE);
            teleopbutton25.setVisibility(View.GONE);
            teleopbutton26.setVisibility(View.GONE);
            teleopbutton27.setVisibility(View.GONE);

            finish.setVisibility(View.VISIBLE);
        });

        //AUTON BUTTON ON CLICK LISTENERS
        autonbutton1.setOnClickListener(new View.OnClickListener() {
            int x = 0;
            @Override
            public void onClick(View view) {
                x++;
                if(x == 1) {
                    autonbutton1.setImageResource(R.drawable.cone);
                }
                if(x == 2) {
                    autonbutton1.setImageResource(R.drawable.cube);
                }
                if(x == 3) {
                    autonbutton1.setImageResource(R.drawable.nothing);
                    x = 0;
                }
            }
        });

        autonbutton2.setOnClickListener(new View.OnClickListener() {
            int x = 0;
            @Override
            public void onClick(View view) {
                x++;
                if(x == 1) {
                    autonbutton2.setImageResource(R.drawable.cone);
                }
                if(x == 2) {
                    autonbutton2.setImageResource(R.drawable.cube);
                }
                if(x == 3) {
                    autonbutton2.setImageResource(R.drawable.nothing);
                    x = 0;
                }
            }
        });

        autonbutton3.setOnClickListener(new View.OnClickListener() {
            int x = 0;
            @Override
            public void onClick(View view) {
                x++;
                if(x == 1) {
                    autonbutton3.setImageResource(R.drawable.cone);
                }
                if(x == 2) {
                    autonbutton3.setImageResource(R.drawable.cube);
                }
                if(x == 3) {
                    autonbutton3.setImageResource(R.drawable.nothing);
                    x = 0;
                }
            }
        });

        autonbutton4.setOnClickListener(new View.OnClickListener() {
            int x = 0;
            @Override
            public void onClick(View view) {
                x++;
                if(x == 1) {
                    autonbutton4.setImageResource(R.drawable.cone);
                }
                if(x == 2) {
                    autonbutton4.setImageResource(R.drawable.cube);
                }
                if(x == 3) {
                    autonbutton4.setImageResource(R.drawable.nothing);
                    x = 0;
                }
            }
        });

        autonbutton5.setOnClickListener(new View.OnClickListener() {
            int x = 0;
            @Override
            public void onClick(View view) {
                x++;
                if(x == 1) {
                    autonbutton5.setImageResource(R.drawable.cone);
                }
                if(x == 2) {
                    autonbutton5.setImageResource(R.drawable.cube);
                }
                if(x == 3) {
                    autonbutton5.setImageResource(R.drawable.nothing);
                    x = 0;
                }
            }
        });

        autonbutton6.setOnClickListener(new View.OnClickListener() {
            int x = 0;
            @Override
            public void onClick(View view) {
                x++;
                if(x == 1) {
                    autonbutton6.setImageResource(R.drawable.cone);
                }
                if(x == 2) {
                    autonbutton6.setImageResource(R.drawable.cube);
                }
                if(x == 3) {
                    autonbutton6.setImageResource(R.drawable.nothing);
                    x = 0;
                }
            }
        });

        autonbutton7.setOnClickListener(new View.OnClickListener() {
            int x = 0;
            @Override
            public void onClick(View view) {
                x++;
                if(x == 1) {
                    autonbutton7.setImageResource(R.drawable.cone);
                }
                if(x == 2) {
                    autonbutton7.setImageResource(R.drawable.cube);
                }
                if(x == 3) {
                    autonbutton7.setImageResource(R.drawable.nothing);
                    x = 0;
                }
            }
        });

        autonbutton8.setOnClickListener(new View.OnClickListener() {
            int x = 0;
            @Override
            public void onClick(View view) {
                x++;
                if(x == 1) {
                    autonbutton8.setImageResource(R.drawable.cone);
                }
                if(x == 2) {
                    autonbutton8.setImageResource(R.drawable.cube);
                }
                if(x == 3) {
                    autonbutton8.setImageResource(R.drawable.nothing);
                    x = 0;
                }
            }
        });

        autonbutton9.setOnClickListener(new View.OnClickListener() {
            int x = 0;
            @Override
            public void onClick(View view) {
                x++;
                if(x == 1) {
                    autonbutton9.setImageResource(R.drawable.cone);
                }
                if(x == 2) {
                    autonbutton9.setImageResource(R.drawable.cube);
                }
                if(x == 3) {
                    autonbutton9.setImageResource(R.drawable.nothing);
                    x = 0;
                }
            }
        });

        autonbutton10.setOnClickListener(new View.OnClickListener() {
            int x = 0;
            @Override
            public void onClick(View view) {
                x++;
                if(x == 1) {
                    autonbutton10.setImageResource(R.drawable.cone);
                }
                if(x == 2) {
                    autonbutton10.setImageResource(R.drawable.cube);
                }
                if(x == 3) {
                    autonbutton10.setImageResource(R.drawable.nothing);
                    x = 0;
                }
            }
        });

        autonbutton11.setOnClickListener(new View.OnClickListener() {
            int x = 0;
            @Override
            public void onClick(View view) {
                x++;
                if(x == 1) {
                    autonbutton11.setImageResource(R.drawable.cone);
                }
                if(x == 2) {
                    autonbutton11.setImageResource(R.drawable.cube);
                }
                if(x == 3) {
                    autonbutton11.setImageResource(R.drawable.nothing);
                    x = 0;
                }
            }
        });

        autonbutton12.setOnClickListener(new View.OnClickListener() {
            int x = 0;
            @Override
            public void onClick(View view) {
                x++;
                if(x == 1) {
                    autonbutton12.setImageResource(R.drawable.cone);
                }
                if(x == 2) {
                    autonbutton12.setImageResource(R.drawable.cube);
                }
                if(x == 3) {
                    autonbutton12.setImageResource(R.drawable.nothing);
                    x = 0;
                }
            }
        });

        autonbutton13.setOnClickListener(new View.OnClickListener() {
            int x = 0;
            @Override
            public void onClick(View view) {
                x++;
                if(x == 1) {
                    autonbutton13.setImageResource(R.drawable.cone);
                }
                if(x == 2) {
                    autonbutton13.setImageResource(R.drawable.cube);
                }
                if(x == 3) {
                    autonbutton13.setImageResource(R.drawable.nothing);
                    x = 0;
                }
            }
        });

        autonbutton14.setOnClickListener(new View.OnClickListener() {
            int x = 0;
            @Override
            public void onClick(View view) {
                x++;
                if(x == 1) {
                    autonbutton14.setImageResource(R.drawable.cone);
                }
                if(x == 2) {
                    autonbutton14.setImageResource(R.drawable.cube);
                }
                if(x == 3) {
                    autonbutton14.setImageResource(R.drawable.nothing);
                    x = 0;
                }
            }
        });

        autonbutton15.setOnClickListener(new View.OnClickListener() {
            int x = 0;
            @Override
            public void onClick(View view) {
                x++;
                if(x == 1) {
                    autonbutton15.setImageResource(R.drawable.cone);
                }
                if(x == 2) {
                    autonbutton15.setImageResource(R.drawable.cube);
                }
                if(x == 3) {
                    autonbutton15.setImageResource(R.drawable.nothing);
                    x = 0;
                }
            }
        });

        autonbutton16.setOnClickListener(new View.OnClickListener() {
            int x = 0;
            @Override
            public void onClick(View view) {
                x++;
                if(x == 1) {
                    autonbutton16.setImageResource(R.drawable.cone);
                }
                if(x == 2) {
                    autonbutton16.setImageResource(R.drawable.cube);
                }
                if(x == 3) {
                    autonbutton16.setImageResource(R.drawable.nothing);
                    x = 0;
                }
            }
        });

        autonbutton17.setOnClickListener(new View.OnClickListener() {
            int x = 0;
            @Override
            public void onClick(View view) {
                x++;
                if(x == 1) {
                    autonbutton17.setImageResource(R.drawable.cone);
                }
                if(x == 2) {
                    autonbutton17.setImageResource(R.drawable.cube);
                }
                if(x == 3) {
                    autonbutton17.setImageResource(R.drawable.nothing);
                    x = 0;
                }
            }
        });

        autonbutton18.setOnClickListener(new View.OnClickListener() {
            int x = 0;
            @Override
            public void onClick(View view) {
                x++;
                if(x == 1) {
                    autonbutton18.setImageResource(R.drawable.cone);
                }
                if(x == 2) {
                    autonbutton18.setImageResource(R.drawable.cube);
                }
                if(x == 3) {
                    autonbutton18.setImageResource(R.drawable.nothing);
                    x = 0;
                }
            }
        });

        autonbutton19.setOnClickListener(new View.OnClickListener() {
            int x = 0;
            @Override
            public void onClick(View view) {
                x++;
                if(x == 1) {
                    autonbutton19.setImageResource(R.drawable.cone);
                }
                if(x == 2) {
                    autonbutton19.setImageResource(R.drawable.cube);
                }
                if(x == 3) {
                    autonbutton19.setImageResource(R.drawable.nothing);
                    x = 0;
                }
            }
        });

        autonbutton20.setOnClickListener(new View.OnClickListener() {
            int x = 0;
            @Override
            public void onClick(View view) {
                x++;
                if(x == 1) {
                    autonbutton20.setImageResource(R.drawable.cone);
                }
                if(x == 2) {
                    autonbutton20.setImageResource(R.drawable.cube);
                }
                if(x == 3) {
                    autonbutton20.setImageResource(R.drawable.nothing);
                    x = 0;
                }
            }
        });

        autonbutton21.setOnClickListener(new View.OnClickListener() {
            int x = 0;
            @Override
            public void onClick(View view) {
                x++;
                if(x == 1) {
                    autonbutton21.setImageResource(R.drawable.cone);
                }
                if(x == 2) {
                    autonbutton21.setImageResource(R.drawable.cube);
                }
                if(x == 3) {
                    autonbutton21.setImageResource(R.drawable.nothing);
                    x = 0;
                }
            }
        });

        autonbutton22.setOnClickListener(new View.OnClickListener() {
            int x = 0;
            @Override
            public void onClick(View view) {
                x++;
                if(x == 1) {
                    autonbutton22.setImageResource(R.drawable.cone);
                }
                if(x == 2) {
                    autonbutton22.setImageResource(R.drawable.cube);
                }
                if(x == 3) {
                    autonbutton22.setImageResource(R.drawable.nothing);
                    x = 0;
                }
            }
        });

        autonbutton23.setOnClickListener(new View.OnClickListener() {
            int x = 0;
            @Override
            public void onClick(View view) {
                x++;
                if(x == 1) {
                    autonbutton23.setImageResource(R.drawable.cone);
                }
                if(x == 2) {
                    autonbutton23.setImageResource(R.drawable.cube);
                }
                if(x == 3) {
                    autonbutton23.setImageResource(R.drawable.nothing);
                    x = 0;
                }
            }
        });

        autonbutton24.setOnClickListener(new View.OnClickListener() {
            int x = 0;
            @Override
            public void onClick(View view) {
                x++;
                if(x == 1) {
                    autonbutton24.setImageResource(R.drawable.cone);
                }
                if(x == 2) {
                    autonbutton24.setImageResource(R.drawable.cube);
                }
                if(x == 3) {
                    autonbutton24.setImageResource(R.drawable.nothing);
                    x = 0;
                }
            }
        });

        autonbutton25.setOnClickListener(new View.OnClickListener() {
            int x = 0;
            @Override
            public void onClick(View view) {
                x++;
                if(x == 1) {
                    autonbutton25.setImageResource(R.drawable.cone);
                }
                if(x == 2) {
                    autonbutton25.setImageResource(R.drawable.cube);
                }
                if(x == 3) {
                    autonbutton25.setImageResource(R.drawable.nothing);
                    x = 0;
                }
            }
        });

        autonbutton26.setOnClickListener(new View.OnClickListener() {
            int x = 0;
            @Override
            public void onClick(View view) {
                x++;
                if(x == 1) {
                    autonbutton26.setImageResource(R.drawable.cone);
                }
                if(x == 2) {
                    autonbutton26.setImageResource(R.drawable.cube);
                }
                if(x == 3) {
                    autonbutton26.setImageResource(R.drawable.nothing);
                    x = 0;
                }
            }
        });

        autonbutton27.setOnClickListener(new View.OnClickListener() {
            int x = 0;
            @Override
            public void onClick(View view) {
                x++;
                if(x == 1) {
                    autonbutton27.setImageResource(R.drawable.cone);
                }
                if(x == 2) {
                    autonbutton27.setImageResource(R.drawable.cube);
                }
                if(x == 3) {
                    autonbutton27.setImageResource(R.drawable.nothing);
                    x = 0;
                }
            }
        });

        //AUTON CHARGE STATION CODE
        autonRed.setOnClickListener(view -> {
            autonRed.setImageResource(R.drawable.red);
            autonYellow.setImageResource(R.drawable.yellow_trans);
            autonGreen.setImageResource(R.drawable.green_trans);
        });

        autonYellow.setOnClickListener(view -> {
            autonRed.setImageResource(R.drawable.red_trans);
            autonYellow.setImageResource(R.drawable.yellow);
            autonGreen.setImageResource(R.drawable.green_trans);
        });

        autonGreen.setOnClickListener(view -> {
            autonRed.setImageResource(R.drawable.red_trans);
            autonYellow.setImageResource(R.drawable.yellow_trans);
            autonGreen.setImageResource(R.drawable.green);
        });


        //TELEOP BUTTON ON CLICK LISTENERS
        teleopbutton1.setOnClickListener(new View.OnClickListener() {
            int x = 0;
            @Override
            public void onClick(View view) {
                x++;
                if(x == 1) {
                    teleopbutton1.setImageResource(R.drawable.cone);
                }
                if(x == 2) {
                    teleopbutton1.setImageResource(R.drawable.cube);
                }
                if(x == 3) {
                    teleopbutton1.setImageResource(R.drawable.nothing);
                    x = 0;
                }
            }
        });

        teleopbutton2.setOnClickListener(new View.OnClickListener() {
            int x = 0;
            @Override
            public void onClick(View view) {
                x++;
                if(x == 1) {
                    teleopbutton2.setImageResource(R.drawable.cone);
                }
                if(x == 2) {
                    teleopbutton2.setImageResource(R.drawable.cube);
                }
                if(x == 3) {
                    teleopbutton2.setImageResource(R.drawable.nothing);
                    x = 0;
                }
            }
        });

        teleopbutton3.setOnClickListener(new View.OnClickListener() {
            int x = 0;
            @Override
            public void onClick(View view) {
                x++;
                if(x == 1) {
                    teleopbutton3.setImageResource(R.drawable.cone);
                }
                if(x == 2) {
                    teleopbutton3.setImageResource(R.drawable.cube);
                }
                if(x == 3) {
                    teleopbutton3.setImageResource(R.drawable.nothing);
                    x = 0;
                }
            }
        });

        teleopbutton4.setOnClickListener(new View.OnClickListener() {
            int x = 0;
            @Override
            public void onClick(View view) {
                x++;
                if(x == 1) {
                    teleopbutton4.setImageResource(R.drawable.cone);
                }
                if(x == 2) {
                    teleopbutton4.setImageResource(R.drawable.cube);
                }
                if(x == 3) {
                    teleopbutton4.setImageResource(R.drawable.nothing);
                    x = 0;
                }
            }
        });

        teleopbutton5.setOnClickListener(new View.OnClickListener() {
            int x = 0;
            @Override
            public void onClick(View view) {
                x++;
                if(x == 1) {
                    teleopbutton5.setImageResource(R.drawable.cone);
                }
                if(x == 2) {
                    teleopbutton5.setImageResource(R.drawable.cube);
                }
                if(x == 3) {
                    teleopbutton5.setImageResource(R.drawable.nothing);
                    x = 0;
                }
            }
        });

        teleopbutton6.setOnClickListener(new View.OnClickListener() {
            int x = 0;
            @Override
            public void onClick(View view) {
                x++;
                if(x == 1) {
                    teleopbutton6.setImageResource(R.drawable.cone);
                }
                if(x == 2) {
                    teleopbutton6.setImageResource(R.drawable.cube);
                }
                if(x == 3) {
                    teleopbutton6.setImageResource(R.drawable.nothing);
                    x = 0;
                }
            }
        });

        teleopbutton7.setOnClickListener(new View.OnClickListener() {
            int x = 0;
            @Override
            public void onClick(View view) {
                x++;
                if(x == 1) {
                    teleopbutton7.setImageResource(R.drawable.cone);
                }
                if(x == 2) {
                    teleopbutton7.setImageResource(R.drawable.cube);
                }
                if(x == 3) {
                    teleopbutton7.setImageResource(R.drawable.nothing);
                    x = 0;
                }
            }
        });

        teleopbutton8.setOnClickListener(new View.OnClickListener() {
            int x = 0;
            @Override
            public void onClick(View view) {
                x++;
                if(x == 1) {
                    teleopbutton8.setImageResource(R.drawable.cone);
                }
                if(x == 2) {
                    teleopbutton8.setImageResource(R.drawable.cube);
                }
                if(x == 3) {
                    teleopbutton8.setImageResource(R.drawable.nothing);
                    x = 0;
                }
            }
        });

        teleopbutton9.setOnClickListener(new View.OnClickListener() {
            int x = 0;
            @Override
            public void onClick(View view) {
                x++;
                if(x == 1) {
                    teleopbutton9.setImageResource(R.drawable.cone);
                }
                if(x == 2) {
                    teleopbutton9.setImageResource(R.drawable.cube);
                }
                if(x == 3) {
                    teleopbutton9.setImageResource(R.drawable.nothing);
                    x = 0;
                }
            }
        });

        teleopbutton10.setOnClickListener(new View.OnClickListener() {
            int x = 0;
            @Override
            public void onClick(View view) {
                x++;
                if(x == 1) {
                    teleopbutton10.setImageResource(R.drawable.cone);
                }
                if(x == 2) {
                    teleopbutton10.setImageResource(R.drawable.cube);
                }
                if(x == 3) {
                    teleopbutton10.setImageResource(R.drawable.nothing);
                    x = 0;
                }
            }
        });

        teleopbutton11.setOnClickListener(new View.OnClickListener() {
            int x = 0;
            @Override
            public void onClick(View view) {
                x++;
                if(x == 1) {
                    teleopbutton11.setImageResource(R.drawable.cone);
                }
                if(x == 2) {
                    teleopbutton11.setImageResource(R.drawable.cube);
                }
                if(x == 3) {
                    teleopbutton11.setImageResource(R.drawable.nothing);
                    x = 0;
                }
            }
        });

        teleopbutton12.setOnClickListener(new View.OnClickListener() {
            int x = 0;
            @Override
            public void onClick(View view) {
                x++;
                if(x == 1) {
                    teleopbutton12.setImageResource(R.drawable.cone);
                }
                if(x == 2) {
                    teleopbutton12.setImageResource(R.drawable.cube);
                }
                if(x == 3) {
                    teleopbutton12.setImageResource(R.drawable.nothing);
                    x = 0;
                }
            }
        });

        teleopbutton13.setOnClickListener(new View.OnClickListener() {
            int x = 0;
            @Override
            public void onClick(View view) {
                x++;
                if(x == 1) {
                    teleopbutton13.setImageResource(R.drawable.cone);
                }
                if(x == 2) {
                    teleopbutton13.setImageResource(R.drawable.cube);
                }
                if(x == 3) {
                    teleopbutton13.setImageResource(R.drawable.nothing);
                    x = 0;
                }
            }
        });

        teleopbutton14.setOnClickListener(new View.OnClickListener() {
            int x = 0;
            @Override
            public void onClick(View view) {
                x++;
                if(x == 1) {
                    teleopbutton14.setImageResource(R.drawable.cone);
                }
                if(x == 2) {
                    teleopbutton14.setImageResource(R.drawable.cube);
                }
                if(x == 3) {
                    teleopbutton14.setImageResource(R.drawable.nothing);
                    x = 0;
                }
            }
        });

        teleopbutton15.setOnClickListener(new View.OnClickListener() {
            int x = 0;
            @Override
            public void onClick(View view) {
                x++;
                if(x == 1) {
                    teleopbutton15.setImageResource(R.drawable.cone);
                }
                if(x == 2) {
                    teleopbutton15.setImageResource(R.drawable.cube);
                }
                if(x == 3) {
                    teleopbutton15.setImageResource(R.drawable.nothing);
                    x = 0;
                }
            }
        });

        teleopbutton16.setOnClickListener(new View.OnClickListener() {
            int x = 0;
            @Override
            public void onClick(View view) {
                x++;
                if(x == 1) {
                    teleopbutton16.setImageResource(R.drawable.cone);
                }
                if(x == 2) {
                    teleopbutton16.setImageResource(R.drawable.cube);
                }
                if(x == 3) {
                    teleopbutton16.setImageResource(R.drawable.nothing);
                    x = 0;
                }
            }
        });

        teleopbutton17.setOnClickListener(new View.OnClickListener() {
            int x = 0;
            @Override
            public void onClick(View view) {
                x++;
                if(x == 1) {
                    teleopbutton17.setImageResource(R.drawable.cone);
                }
                if(x == 2) {
                    teleopbutton17.setImageResource(R.drawable.cube);
                }
                if(x == 3) {
                    teleopbutton17.setImageResource(R.drawable.nothing);
                    x = 0;
                }
            }
        });

        teleopbutton18.setOnClickListener(new View.OnClickListener() {
            int x = 0;
            @Override
            public void onClick(View view) {
                x++;
                if(x == 1) {
                    teleopbutton18.setImageResource(R.drawable.cone);
                }
                if(x == 2) {
                    teleopbutton18.setImageResource(R.drawable.cube);
                }
                if(x == 3) {
                    teleopbutton18.setImageResource(R.drawable.nothing);
                    x = 0;
                }
            }
        });

        teleopbutton19.setOnClickListener(new View.OnClickListener() {
            int x = 0;
            @Override
            public void onClick(View view) {
                x++;
                if(x == 1) {
                    teleopbutton19.setImageResource(R.drawable.cone);
                }
                if(x == 2) {
                    teleopbutton19.setImageResource(R.drawable.cube);
                }
                if(x == 3) {
                    teleopbutton19.setImageResource(R.drawable.nothing);
                    x = 0;
                }
            }
        });

        teleopbutton20.setOnClickListener(new View.OnClickListener() {
            int x = 0;
            @Override
            public void onClick(View view) {
                x++;
                if(x == 1) {
                    teleopbutton20.setImageResource(R.drawable.cone);
                }
                if(x == 2) {
                    teleopbutton20.setImageResource(R.drawable.cube);
                }
                if(x == 3) {
                    teleopbutton20.setImageResource(R.drawable.nothing);
                    x = 0;
                }
            }
        });

        teleopbutton21.setOnClickListener(new View.OnClickListener() {
            int x = 0;
            @Override
            public void onClick(View view) {
                x++;
                if(x == 1) {
                    teleopbutton21.setImageResource(R.drawable.cone);
                }
                if(x == 2) {
                    teleopbutton21.setImageResource(R.drawable.cube);
                }
                if(x == 3) {
                    teleopbutton21.setImageResource(R.drawable.nothing);
                    x = 0;
                }
            }
        });

        teleopbutton22.setOnClickListener(new View.OnClickListener() {
            int x = 0;
            @Override
            public void onClick(View view) {
                x++;
                if(x == 1) {
                    teleopbutton22.setImageResource(R.drawable.cone);
                }
                if(x == 2) {
                    teleopbutton22.setImageResource(R.drawable.cube);
                }
                if(x == 3) {
                    teleopbutton22.setImageResource(R.drawable.nothing);
                    x = 0;
                }
            }
        });

        teleopbutton23.setOnClickListener(new View.OnClickListener() {
            int x = 0;
            @Override
            public void onClick(View view) {
                x++;
                if(x == 1) {
                    teleopbutton23.setImageResource(R.drawable.cone);
                }
                if(x == 2) {
                    teleopbutton23.setImageResource(R.drawable.cube);
                }
                if(x == 3) {
                    teleopbutton23.setImageResource(R.drawable.nothing);
                    x = 0;
                }
            }
        });

        teleopbutton24.setOnClickListener(new View.OnClickListener() {
            int x = 0;
            @Override
            public void onClick(View view) {
                x++;
                if(x == 1) {
                    teleopbutton24.setImageResource(R.drawable.cone);
                }
                if(x == 2) {
                    teleopbutton24.setImageResource(R.drawable.cube);
                }
                if(x == 3) {
                    teleopbutton24.setImageResource(R.drawable.nothing);
                    x = 0;
                }
            }
        });

        teleopbutton25.setOnClickListener(new View.OnClickListener() {
            int x = 0;
            @Override
            public void onClick(View view) {
                x++;
                if(x == 1) {
                    teleopbutton25.setImageResource(R.drawable.cone);
                }
                if(x == 2) {
                    teleopbutton25.setImageResource(R.drawable.cube);
                }
                if(x == 3) {
                    teleopbutton25.setImageResource(R.drawable.nothing);
                    x = 0;
                }
            }
        });

        teleopbutton26.setOnClickListener(new View.OnClickListener() {
            int x = 0;
            @Override
            public void onClick(View view) {
                x++;
                if(x == 1) {
                    teleopbutton26.setImageResource(R.drawable.cone);
                }
                if(x == 2) {
                    teleopbutton26.setImageResource(R.drawable.cube);
                }
                if(x == 3) {
                    teleopbutton26.setImageResource(R.drawable.nothing);
                    x = 0;
                }
            }
        });

        teleopbutton27.setOnClickListener(new View.OnClickListener() {
            int x = 0;
            @Override
            public void onClick(View view) {
                x++;
                if(x == 1) {
                    teleopbutton27.setImageResource(R.drawable.cone);
                }
                if(x == 2) {
                    teleopbutton27.setImageResource(R.drawable.cube);
                }
                if(x == 3) {
                    teleopbutton27.setImageResource(R.drawable.nothing);
                    x = 0;
                }
            }
        });

        finish.setOnClickListener(view -> {
                getParentFragmentManager().beginTransaction().replace(R.id.body_container, new QRPage()).commit();
        });
        return inputView;
    }
}