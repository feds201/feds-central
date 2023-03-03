package com.feds201.scoutingapp2023;

import android.annotation.SuppressLint;
import android.os.Bundle;

import androidx.fragment.app.Fragment;

import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.CheckBox;
import android.widget.ImageButton;
import android.widget.RadioButton;
import android.widget.SeekBar;
import android.widget.TextView;

import com.feds201.scoutingapp2023.component.GamePieceButton;

import java.lang.reflect.Field;
import java.util.ArrayList;


public class Input extends Fragment {
    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        View inputView = inflater.inflate(R.layout.fragment_input, container, false);
        //READ QR PAGE BEFORE WORKING!!!!!!!!!!!!!!!!!!!!!!!!
        //For the grid (Make button class instead of this bs)
        //This example is with the top middle button
        //Im assuming in the qr cone means 0, cube means 1, nothing means 2, or something like that
        //Also use some variable to keep track of how many cubes / cones on each row

        //TAB SYSTEM
        ImageButton autontab = inputView.findViewById(R.id.autontab);
        ImageButton teleoptab = inputView.findViewById(R.id.teleoptab);
        ImageButton endgametab = inputView.findViewById(R.id.endgametab);

        //EVERYTHING ON AUTON PAGE
        ArrayList<GamePieceButton> autonButtons = GamePieceButton.generateCyclingButtonsFromPrefix(R.id.class, "autonbutton", inputView);
        ImageButton autonGreen = inputView.findViewById(R.id.auton_green);
        ImageButton autonYellow = inputView.findViewById(R.id.auton_yellow);
        ImageButton autonRed = inputView.findViewById(R.id.auton_red);

        //EVERYTHING ON TELEOP PAGE
        ArrayList<GamePieceButton> teleopButtons = GamePieceButton.generateCyclingButtonsFromPrefix(R.id.class, "teleopbutton", inputView);
        SeekBar teleopstrategyseekbar = inputView.findViewById(R.id.teleop_strategybar);
        CheckBox coopertitioncheckbox = inputView.findViewById(R.id.teleop_coopertition);
        RadioButton team1 = inputView.findViewById(R.id.radioButton1);
        RadioButton team2 = inputView.findViewById(R.id.radioButton2);
        RadioButton team3 = inputView.findViewById(R.id.radioButton3);
        TextView strategyTitle = inputView.findViewById(R.id.teleop_strategyviewtext);

        //EVERYTHING ON ENDGAME PAGE
        Button finish = inputView.findViewById(R.id.endgame_finish);
        ImageButton endgameGreen = inputView.findViewById(R.id.endgame_green);
        ImageButton endgameYellow = inputView.findViewById(R.id.endgame_yellow);
        ImageButton endgameRed = inputView.findViewById(R.id.endgame_red);

        teleopstrategyseekbar.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener() {
            @Override
            public void onProgressChanged(SeekBar seekBar, int i, boolean b) {
                if(i == 0) {
                    strategyTitle.setText("Please Select An Option!");
                } else if(i == 1) {
                    strategyTitle.setText("Feeding");
                } else if(i == 2) {
                    strategyTitle.setText("Placing");
                } else if (i == 3){
                    strategyTitle.setText("Both");
                }
            }

            @Override
            public void onStartTrackingTouch(SeekBar seekBar) {

            }

            @Override
            public void onStopTrackingTouch(SeekBar seekBar) {

            }
        });


        // 1-9   is high
        // 10-18 is med
        // 19-27 is low
        Class resClass = R.id.class;
        Field[] fields = resClass.getFields();

        ArrayList<View> allAutonViews = new ArrayList<>();
        ArrayList<View> allTeleopViews = new ArrayList<>();
        ArrayList<View> allEndgameViews = new ArrayList<>();

        for(Field field : fields) {
            if(!field.getName().contains("tab") && !field.getName().contains("checkbox")) {
                if(field.getName().contains("auton")){
                    try {
                        int id = field.getInt(resClass);
                        allAutonViews.add(inputView.findViewById(id));
                    } catch (IllegalAccessException e) {
                        throw new RuntimeException(e);
                    }
                } else if (field.getName().contains("teleop")){
                    try {
                        int id = field.getInt(resClass);
                        allTeleopViews.add(inputView.findViewById(id));
                    } catch (IllegalAccessException e) {
                        throw new RuntimeException(e);
                    }
                } else if (field.getName().contains("endgame")){
                    try {
                        int id = field.getInt(resClass);
                        allEndgameViews.add(inputView.findViewById(id));
                    } catch (IllegalAccessException e) {
                        throw new RuntimeException(e);
                    }
                }
            }
        }


        //STUFF THAT SHOULD BE HIDDEN WHILE APP IS ON START
        // teleop disabled and hidden
        for(View v : allTeleopViews) {
            v.setVisibility(View.GONE);
        }
        for(View v : allEndgameViews) {
            v.setVisibility(View.GONE);
        }

        //TAB SWITCHING
        autontab.setOnClickListener(view -> {
            // auton visible and active
            autontab.setImageResource(R.drawable.autontab);
            for(View v : allAutonViews) {
                v.setVisibility(View.VISIBLE);
            }

            // teleop transparent and disabled
            teleoptab.setImageResource(R.drawable.teleoptabtrans);
            for(View v : allTeleopViews) {
                v.setVisibility(View.GONE);
            }

            // finish transparent and disabled
            endgametab.setImageResource(R.drawable.endgametabtrans);
            for(View v : allEndgameViews) {
                v.setVisibility(View.GONE);
            }
        });

        teleoptab.setOnClickListener(view -> {
            autontab.setImageResource(R.drawable.autontabtrans);
            for(View v : allAutonViews) {
                v.setVisibility(View.GONE);
            }

            teleoptab.setImageResource(R.drawable.teleoptab);
            for(View v : allTeleopViews) {
                v.setVisibility(View.VISIBLE);
            }

            endgametab.setImageResource(R.drawable.endgametabtrans);
            for(View v : allEndgameViews) {
                v.setVisibility(View.GONE);
            }
        });

        endgametab.setOnClickListener(view -> {
            autontab.setImageResource(R.drawable.autontabtrans);
            for(View v : allAutonViews) {
                v.setVisibility(View.GONE);
            }

            teleoptab.setImageResource(R.drawable.teleoptabtrans);
            for(View v : allTeleopViews) {
                v.setVisibility(View.GONE);
            }

            endgametab.setImageResource(R.drawable.endgametab);
            for(View v : allEndgameViews) {
                v.setVisibility(View.VISIBLE);
            }
        });

        //AUTON BUTTON ON CLICK LISTENERS
        for(GamePieceButton gamePieceButton : autonButtons) {
            Log.d("DEBUG", gamePieceButton.toString());
            gamePieceButton.button.setOnClickListener(view -> {
                gamePieceButton.cycleImage();
            });
        }

        for(GamePieceButton gamePieceButton : teleopButtons) {
            Log.d("DEBUG", gamePieceButton.toString());
            gamePieceButton.button.setOnClickListener(view -> {
                gamePieceButton.cycleImage();
            });
        }

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

        //ENDGAME CHARGE STATION CODE
        endgameRed.setOnClickListener(view -> {
            endgameRed.setImageResource(R.drawable.red);
            endgameYellow.setImageResource(R.drawable.yellow_trans);
            endgameGreen.setImageResource(R.drawable.green_trans);
        });

        endgameYellow.setOnClickListener(view -> {
            endgameRed.setImageResource(R.drawable.red_trans);
            endgameYellow.setImageResource(R.drawable.yellow);
            endgameGreen.setImageResource(R.drawable.green_trans);
        });

        endgameGreen.setOnClickListener(view -> {
            endgameRed.setImageResource(R.drawable.red_trans);
            endgameYellow.setImageResource(R.drawable.yellow_trans);
            endgameGreen.setImageResource(R.drawable.green);
        });

        finish.setOnClickListener(view -> {
                getParentFragmentManager().beginTransaction().replace(R.id.body_container, new QRPage()).commit();
        });
        return inputView;
    }
}