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
import com.feds201.scoutingapp2023.component.Tally;
import com.feds201.scoutingapp2023.sql.Match;
import com.feds201.scoutingapp2023.sql.MatchDao;

import java.lang.reflect.Field;
import java.util.ArrayList;


public class Input extends Fragment {

    public static Match currentMatch = null;

    @SuppressLint("SetTextI18n")
    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        View inputView = inflater.inflate(R.layout.fragment_input, container, false);

        /*
            Table of Contents
            ---------------------------------------------------
            1. Initialize all objects
                a. tabs
                b. auton page objects
                c. teleop page objects
                d. endgame page objects
            2. Find all objects with certain prefixes
                a. exclude tabs
                b. auton
                c. teleop
                d. endgame
            3. Hiding objects on tab switch
                a. objects hidden on start
                b. auton tab active
                c. teleop tab active
                d. endgame tab active
            4. Component specific code
                a. auton grid button listeners
                b. teleop grid button listeners
                c. tally event listeners
                d. teleop seek bar event listeners
                e. auton stop light
                f. endgame stop light
                g. advance page on finish button press
          */

        //READ QR PAGE BEFORE WORKING!!!!!!!!!!!!!!!!!!!!!!!!

        MatchDao matchDao = MainActivity.app_db.matchDao();
        if (currentMatch == null) {
            currentMatch = new Match();
            currentMatch.matchType = "ERROR";
            currentMatch.color = "NONE";
        }

        currentMatch.generateAutonGridFromString();
        currentMatch.generateTeleopGridFromString();


        TextView colorText = inputView.findViewById(R.id.Team_color_title);
        TextView matchText = inputView.findViewById(R.id.Match_title);
        TextView teamNumberText = inputView.findViewById(R.id.Team_number_title);

        colorText.setText(currentMatch.color + " " + currentMatch.colorNumber);
        matchText.setText(currentMatch.matchType + " " + currentMatch.matchNumber);
        teamNumberText.setText("" + currentMatch.teamNumber);

        // 1. Initialize all objects
        // 1a. tabs
        ImageButton autontab = inputView.findViewById(R.id.autontab);
        ImageButton teleoptab = inputView.findViewById(R.id.teleoptab);
        ImageButton endgametab = inputView.findViewById(R.id.endgametab);

        // 1b. auton page objects
        ArrayList<GamePieceButton> autonButtons = GamePieceButton.generateCyclingButtonsFromPrefix(R.id.class, "auton_button", inputView);
        ImageButton autonGreen  = inputView.findViewById(R.id.auton_green);
        ImageButton autonYellow = inputView.findViewById(R.id.auton_yellow);
        ImageButton autonRed    = inputView.findViewById(R.id.auton_red);

        Button autonplus        = inputView.findViewById(R.id.auton_plus);
        Button autonminus       = inputView.findViewById(R.id.auton_minus);
        TextView tally          = inputView.findViewById(R.id.auton_tally);
        Tally droppedTally      = new Tally(autonplus, autonminus, tally);

        Button autonplus2       = inputView.findViewById(R.id.auton_plus2);
        Button autonminus2      = inputView.findViewById(R.id.auton_minus2);
        TextView tally2         = inputView.findViewById(R.id.auton_tally2);
        Tally acquiredTally     = new Tally(autonplus2, autonminus2, tally2);

        // 1c. teleop page objects
        ArrayList<GamePieceButton> teleopButtons = GamePieceButton.generateCyclingButtonsFromPrefix(R.id.class, "teleop_button", inputView);
        SeekBar teleopstrategyseekbar = inputView.findViewById(R.id.teleop_strategybar);
        CheckBox coopertitioncheckbox = inputView.findViewById(R.id.teleop_coopertition);
        RadioButton team1 = inputView.findViewById(R.id.radioButton1);
        RadioButton team2 = inputView.findViewById(R.id.radioButton2);
        RadioButton team3 = inputView.findViewById(R.id.radioButton3);
        TextView strategyTitle = inputView.findViewById(R.id.teleop_strategyviewtext);

        // 1d. endgame page objects
        Button finish = inputView.findViewById(R.id.endgame_finish);
        ImageButton endgameGreen  = inputView.findViewById(R.id.endgame_green);
        ImageButton endgameYellow = inputView.findViewById(R.id.endgame_yellow);
        ImageButton endgameRed    = inputView.findViewById(R.id.endgame_red);

        Button endgameminus = inputView.findViewById(R.id.endgame_minus);
        Button endgameplus = inputView.findViewById(R.id.endgame_plus);
        TextView endtally = inputView.findViewById(R.id.endgame_tally);
        Tally linksTally = new Tally(endgameplus, endgameminus, endtally);
        CheckBox parkedcheckbox = inputView.findViewById(R.id.endgame_parked);


        // 2. Find all objects with certain prefixes
        Class resClass = R.id.class;
        Field[] fields = resClass.getFields();

        ArrayList<View> allAutonViews = new ArrayList<>();
        ArrayList<View> allTeleopViews = new ArrayList<>();
        ArrayList<View> allEndgameViews = new ArrayList<>();

        for(Field field : fields) {
            // 2a. exclude tabs
            if(!field.getName().contains("tab")) {
                // 2b. auton
                if(field.getName().contains("auton")){
                    try {
                        int id = field.getInt(resClass);
                        allAutonViews.add(inputView.findViewById(id));
                    } catch (IllegalAccessException e) {
                        throw new RuntimeException(e);
                    }
                } // 2c. teleop
                else if (field.getName().contains("teleop")){
                    try {
                        int id = field.getInt(resClass);
                        allTeleopViews.add(inputView.findViewById(id));
                    } catch (IllegalAccessException e) {
                        throw new RuntimeException(e);
                    }
                } // 2d. endgame
                else if (field.getName().contains("endgame")){
                    try {
                        int id = field.getInt(resClass);
                        allEndgameViews.add(inputView.findViewById(id));
                    } catch (IllegalAccessException e) {
                        throw new RuntimeException(e);
                    }
                }
            }
        }

        // SET UP ALL VIEWS
        for (GamePieceButton gpb : autonButtons) {
            int row = gpb.getRowFromScoreType(gpb.getScoreType());
            int col = gpb.getColNum()-1;


            Match.GamePiece type = currentMatch.autonGrid[row][col];

            switch(type) {
                case CONE:
                    gpb.button.setImageResource(R.drawable.cone);
                    gpb.imageState = 1;
                    break;

                case CUBE:
                    gpb.button.setImageResource(R.drawable.cube);
                    gpb.imageState = 2;
                    break;

                case NONE:
                    gpb.button.setImageResource(R.drawable.nothing);
                    gpb.imageState = 0;
                    break;
            }
        }

        for (GamePieceButton gpb : teleopButtons) {
            int row = gpb.getRowFromScoreType(gpb.getScoreType());
            int col = gpb.getColNum()-1;

            Log.d("gamepiece", "" + row + ", " + col + " " + gpb.getScoreType().toString() + " " + gpb.toString());
            Match.GamePiece type = currentMatch.teleopGrid[row][col];
            Log.d("gamepiece", type.toString());

            switch(type) {
                case CONE:
                    gpb.button.setImageResource(R.drawable.cone);
                    gpb.imageState = 1;
                    break;

                case CUBE:
                    gpb.button.setImageResource(R.drawable.cube);
                    gpb.imageState = 2;
                    break;

                case NONE:
                    gpb.button.setImageResource(R.drawable.nothing);
                    gpb.imageState = 0;
                    break;
            }
        }

        linksTally.text.setText(String.valueOf(currentMatch.links));
        droppedTally.text.setText(String.valueOf(currentMatch.autonDropped));

        coopertitioncheckbox.setChecked(currentMatch.coop == 1);
        parkedcheckbox.setChecked(currentMatch.teleopPark == 1);


        switch(currentMatch.autonCharge) {
            case 0:
                autonRed.setImageResource(R.drawable.red);
                autonYellow.setImageResource(R.drawable.yellow_trans);
                autonGreen.setImageResource(R.drawable.green_trans);
                break;
            case 1:
                autonRed.setImageResource(R.drawable.red_trans);
                autonYellow.setImageResource(R.drawable.yellow);
                autonGreen.setImageResource(R.drawable.green_trans);
                break;
            case 2:
                autonRed.setImageResource(R.drawable.red_trans);
                autonYellow.setImageResource(R.drawable.yellow_trans);
                autonGreen.setImageResource(R.drawable.green);
                break;
        }

        switch(currentMatch.teleopCharge) {
            case 0:
                endgameRed.setImageResource(R.drawable.red);
                endgameYellow.setImageResource(R.drawable.yellow_trans);
                endgameGreen.setImageResource(R.drawable.green_trans);
                break;
            case 1:
                endgameRed.setImageResource(R.drawable.red_trans);
                endgameYellow.setImageResource(R.drawable.yellow);
                endgameGreen.setImageResource(R.drawable.green_trans);
                break;
            case 2:
                endgameRed.setImageResource(R.drawable.red_trans);
                endgameYellow.setImageResource(R.drawable.yellow_trans);
                endgameGreen.setImageResource(R.drawable.green);
                break;
        }

        teleopstrategyseekbar.setProgress(currentMatch.feedPlaceBoth);
        switch (currentMatch.feedPlaceBoth) {
            case 0:
                strategyTitle.setText("Feeding");
                break;
            case 1:
                strategyTitle.setText("Placing");
                break;
            case 2:
                strategyTitle.setText("Both");
                break;
        }


        // 3. Hiding objects on tab switch
        // 3a. objects hidden on start
        for(View v : allTeleopViews) {
            v.setVisibility(View.GONE);
        }
        for(View v : allEndgameViews) {
            v.setVisibility(View.GONE);
        }

        // 3b. auton tab active
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

        // 3c. teleop tab active
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

        // 3c. endgame tab active
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

        // 4. Component specific code
        // 4a. auton grid button listeners
        for(GamePieceButton gamePieceButton : autonButtons) {
                gamePieceButton.button.setOnClickListener(view -> {
                    Log.d("score", "auton: " + currentMatch.autonLow + " " + currentMatch.autonMiddle + " " + currentMatch.autonHigh);

                    int row = gamePieceButton.getRowFromScoreType(gamePieceButton.getScoreType());
                    int col = gamePieceButton.getColNum()-1;

                    if(gamePieceButton.getCycleAll()) {
                        gamePieceButton.imageState++;
                        switch(gamePieceButton.imageState) {
                            case 1:
                                gamePieceButton.button.setImageResource(R.drawable.cone);
                                currentMatch.setAutonGrid(row, col, Match.GamePiece.CONE);
                                Log.d("score", gamePieceButton.getScoreType().toString());
                                switch(gamePieceButton.getScoreType()) {
                                    case AUTON_LOW:
                                        currentMatch.autonLow++;
                                        matchDao.update(currentMatch);
                                        break;
                                    case AUTON_MIDDLE:
                                        currentMatch.autonMiddle++;
//                                        currentMatch.autonGrid[1][gamePieceButton.getButtonId()-1] = Match.GamePiece.CONE;
                                        matchDao.update(currentMatch);
                                        break;
                                    case AUTON_HIGH:
                                        currentMatch.autonHigh++;
//                                        currentMatch.autonGrid[0][gamePieceButton.getButtonId()-1] = Match.GamePiece.CONE;
                                        matchDao.update(currentMatch);
                                        break;
                                }
                                break;
                            case 2:
                                currentMatch.setAutonGrid(row, col, Match.GamePiece.CUBE);
                                gamePieceButton.button.setImageResource(R.drawable.cube);
                                break;
                            case 3:
                                currentMatch.setAutonGrid(row, col, Match.GamePiece.NONE);
                                gamePieceButton.button.setImageResource(R.drawable.nothing);
                                gamePieceButton.imageState = 0;
                                switch(gamePieceButton.getScoreType()) {
                                    case AUTON_LOW:
                                        currentMatch.autonLow--;
                                        matchDao.update(currentMatch);
                                        break;
                                    case AUTON_MIDDLE:
                                        currentMatch.autonMiddle--;
                                        matchDao.update(currentMatch);
                                        break;
                                    case AUTON_HIGH:
                                        currentMatch.autonHigh--;
                                        matchDao.update(currentMatch);
                                        break;
                                }
                                break;
                            default:
                                gamePieceButton.imageState = 0;
                                break;
                        }
                    } else {
                        gamePieceButton.imageState++;
                        switch(gamePieceButton.imageState) {
                            case 1:
                                gamePieceButton.button.setImageResource(R.drawable.cube);
                                currentMatch.setAutonGrid(row, col, Match.GamePiece.CUBE);
                                switch(gamePieceButton.getScoreType()) {
                                    case AUTON_LOW:
                                        currentMatch.autonLow++;
                                        matchDao.update(currentMatch);
                                        break;
                                    case AUTON_MIDDLE:
                                        currentMatch.autonMiddle++;
                                        matchDao.update(currentMatch);
                                        break;
                                    case AUTON_HIGH:
                                        currentMatch.autonHigh++;
                                        matchDao.update(currentMatch);
                                        break;
                                }
                                break;
                            case 2:
                                currentMatch.setAutonGrid(row, col, Match.GamePiece.NONE);
                                gamePieceButton.button.setImageResource(R.drawable.nothing);
                                gamePieceButton.imageState = 0;
                                switch(gamePieceButton.getScoreType()) {
                                    case AUTON_LOW:
                                        currentMatch.autonLow--;
                                        matchDao.update(currentMatch);
                                        break;
                                    case AUTON_MIDDLE:
                                        currentMatch.autonMiddle--;
                                        matchDao.update(currentMatch);
                                        break;
                                    case AUTON_HIGH:
                                        currentMatch.autonHigh--;
                                        matchDao.update(currentMatch);
                                        break;
                                }
                                break;
                            default:
                                gamePieceButton.imageState = 0;
                                break;
                        }

                    }
                    Log.d("score", "" + gamePieceButton.imageState);
               });
        }

        // 4b. teleop grid button listeners
        for(GamePieceButton gamePieceButton : teleopButtons) {
            gamePieceButton.button.setOnClickListener(view -> {
                int row = gamePieceButton.getRowFromScoreType(gamePieceButton.getScoreType());
                int col = gamePieceButton.getColNum()-1;
                Log.d("score", "teleop: " + currentMatch.teleopLow + " " + currentMatch.teleopMiddle + " " + currentMatch.teleopHigh);
                Log.d("score", currentMatch.teleopGridString);
                if (gamePieceButton.getCycleAll()) {
                    gamePieceButton.imageState++;
                    switch(gamePieceButton.imageState) {
                        case 1:
                            currentMatch.setTeleopGrid(row, col, Match.GamePiece.CONE);
                            gamePieceButton.button.setImageResource(R.drawable.cone);
                            switch(gamePieceButton.getScoreType()) {
                                case TELEOP_LOW:
                                    currentMatch.teleopLow++;
                                    matchDao.update(currentMatch);
                                    break;
                                case TELEOP_MIDDLE:
                                    currentMatch.teleopMiddle++;
                                    matchDao.update(currentMatch);
                                    break;
                                case TELEOP_HIGH:
                                    currentMatch.teleopHigh++;
                                    matchDao.update(currentMatch);
                                    break;
                            }
                            break;
                        case 2:
                            currentMatch.setTeleopGrid(row, col, Match.GamePiece.CUBE);
                            gamePieceButton.button.setImageResource(R.drawable.cube);
                            break;
                        case 3:
                            currentMatch.setTeleopGrid(row, col, Match.GamePiece.NONE);
                            gamePieceButton.button.setImageResource(R.drawable.nothing);
                            gamePieceButton.imageState = 0;
                            switch(gamePieceButton.getScoreType()) {
                                case TELEOP_LOW:
                                    currentMatch.teleopLow--;
                                    matchDao.update(currentMatch);
                                    break;
                                case TELEOP_MIDDLE:
                                    currentMatch.teleopMiddle--;
                                    matchDao.update(currentMatch);
                                    break;
                                case TELEOP_HIGH:
                                    currentMatch.teleopHigh--;
                                    matchDao.update(currentMatch);
                                    break;
                            }
                            break;
                        default:
                            gamePieceButton.imageState = 0;
                            break;
                    }
                } else {
                    gamePieceButton.imageState++;
                    switch (gamePieceButton.imageState) {
                        case 1:
                            currentMatch.setTeleopGrid(row, col, Match.GamePiece.CUBE);
                            gamePieceButton.button.setImageResource(R.drawable.cube);
                            switch(gamePieceButton.getScoreType()) {
                                case TELEOP_LOW:
                                    currentMatch.teleopLow++;
                                    matchDao.update(currentMatch);
                                    break;
                                case TELEOP_MIDDLE:
                                    currentMatch.teleopMiddle++;
                                    matchDao.update(currentMatch);
                                    break;
                                case TELEOP_HIGH:
                                    currentMatch.teleopHigh++;
                                    matchDao.update(currentMatch);
                                    break;
                            }
                            break;
                        case 2:
                            currentMatch.setTeleopGrid(row, col, Match.GamePiece.NONE);
                            gamePieceButton.button.setImageResource(R.drawable.nothing);
                            gamePieceButton.imageState = 0;
                            switch(gamePieceButton.getScoreType()) {
                                case TELEOP_LOW:
                                    currentMatch.teleopLow--;
                                    matchDao.update(currentMatch);
                                    break;
                                case TELEOP_MIDDLE:
                                    currentMatch.teleopMiddle--;
                                    matchDao.update(currentMatch);
                                    break;
                                case TELEOP_HIGH:
                                    currentMatch.teleopHigh--;
                                    matchDao.update(currentMatch);
                                    break;
                            }
                            break;
                        default:
                            gamePieceButton.imageState = 0;
                            break;
                    }
                }
            });
        }

        // 4c. tally event listeners
        linksTally.minus.setOnClickListener(v -> {
            int x = Integer.parseInt((linksTally.text.getText().toString()));
            x--;
            if (x < 0) { x = 0; }
            linksTally.text.setText(Integer.toString(x));
            currentMatch.links = x;
            matchDao.update(currentMatch);
        });
        linksTally.plus.setOnClickListener(v -> {
            int x = Integer.parseInt((linksTally.text.getText().toString()));
            x++;
            linksTally.text.setText(Integer.toString(x));
            currentMatch.links = x;
            matchDao.update(currentMatch);
        });

        droppedTally.minus.setOnClickListener(v -> {
            int x = Integer.parseInt((droppedTally.text.getText().toString()));
            x--;
            if (x < 0) { x = 0; }
            droppedTally.text.setText(Integer.toString(x));
            currentMatch.autonDropped = x;
            matchDao.update(currentMatch);
        });
        droppedTally.plus.setOnClickListener(v -> {
            int x = Integer.parseInt((droppedTally.text.getText().toString()));
            x++;
            droppedTally.text.setText(Integer.toString(x));
            currentMatch.autonDropped = x;
            matchDao.update(currentMatch);
        });

        acquiredTally.minus.setOnClickListener(v -> {
            int x = Integer.parseInt((acquiredTally.text.getText().toString()));
            x--;
            if (x < 0) { x = 0; }
            acquiredTally.text.setText(Integer.toString(x));
            matchDao.update(currentMatch);
        });
        acquiredTally.plus.setOnClickListener(v -> {
            int x = Integer.parseInt((acquiredTally.text.getText().toString()));
            x++;
            acquiredTally.text.setText(Integer.toString(x));
            matchDao.update(currentMatch);
        });

        // 4d. teleop seek bar event listeners
        teleopstrategyseekbar.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener() {
            @Override
            public void onProgressChanged(SeekBar seekBar, int i, boolean b) {
                if(i == 0) {
                    strategyTitle.setText("Please Select An Option!");
                } else if(i == 1) {
                    strategyTitle.setText("Feeding");
                    currentMatch.feedPlaceBoth = 0;
                    matchDao.update(currentMatch);
                } else if(i == 2) {
                    strategyTitle.setText("Placing");
                    matchDao.update(currentMatch);
                    currentMatch.feedPlaceBoth = 1;
                } else if (i == 3){
                    strategyTitle.setText("Both");
                    matchDao.update(currentMatch);
                    currentMatch.feedPlaceBoth = 2;
                }
            }

            @Override
            public void onStartTrackingTouch(SeekBar seekBar) {

            }

            @Override
            public void onStopTrackingTouch(SeekBar seekBar) {

            }
        });

        // 4e. auton stop light event listeners
        autonRed.setOnClickListener(view -> {
            currentMatch.autonCharge = 0;
            matchDao.update(currentMatch);
            autonRed.setImageResource(R.drawable.red);
            autonYellow.setImageResource(R.drawable.yellow_trans);
            autonGreen.setImageResource(R.drawable.green_trans);
        });

        autonYellow.setOnClickListener(view -> {
            currentMatch.autonCharge = 1;
            matchDao.update(currentMatch);
            autonRed.setImageResource(R.drawable.red_trans);
            autonYellow.setImageResource(R.drawable.yellow);
            autonGreen.setImageResource(R.drawable.green_trans);
        });

        autonGreen.setOnClickListener(view -> {
            currentMatch.autonCharge = 2;
            matchDao.update(currentMatch);
            autonRed.setImageResource(R.drawable.red_trans);
            autonYellow.setImageResource(R.drawable.yellow_trans);
            autonGreen.setImageResource(R.drawable.green);
        });

        // 4f. endgame stop light event listeners
        endgameRed.setOnClickListener(view -> {
            currentMatch.teleopCharge = 0;
            matchDao.update(currentMatch);
            endgameRed.setImageResource(R.drawable.red);
            endgameYellow.setImageResource(R.drawable.yellow_trans);
            endgameGreen.setImageResource(R.drawable.green_trans);
        });

        endgameYellow.setOnClickListener(view -> {
            currentMatch.teleopCharge = 1;
            matchDao.update(currentMatch);
            endgameRed.setImageResource(R.drawable.red_trans);
            endgameYellow.setImageResource(R.drawable.yellow);
            endgameGreen.setImageResource(R.drawable.green_trans);
        });

        endgameGreen.setOnClickListener(view -> {
            currentMatch.teleopCharge = 2;
            matchDao.update(currentMatch);
            endgameRed.setImageResource(R.drawable.red_trans);
            endgameYellow.setImageResource(R.drawable.yellow_trans);
            endgameGreen.setImageResource(R.drawable.green);
        });

       coopertitioncheckbox.setOnClickListener(view -> {
           if(coopertitioncheckbox.isChecked()) {
               currentMatch.coop = 1;
           }
           else {
               currentMatch.coop = 0;
           }
           matchDao.update(currentMatch);
       });


        parkedcheckbox.setOnClickListener(view -> {
            if(parkedcheckbox.isChecked()) {
                currentMatch.teleopPark = 1;
            }
            else {
                currentMatch.teleopPark = 0;
            }
            matchDao.update(currentMatch);
        });

        // 4g. advance to QRPage on finish button press
        finish.setOnClickListener(view -> {
                getParentFragmentManager().beginTransaction().replace(R.id.body_container, new QRPage()).commit();
        });
        return inputView;
    }
}