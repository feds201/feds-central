package com.feds201.scoutingapp2023.sql;


import android.util.Log;

import androidx.annotation.NonNull;
import androidx.room.ColumnInfo;
import androidx.room.Entity;
import androidx.room.Ignore;
import androidx.room.PrimaryKey;

/* Hi welcome to Zayn's (crazed) SQL brain dump
 * our team number
 * match number
 * opponent teams (csv?)
 * match type (F/SF/Q/EF/QF)
 *
 */


@Entity(tableName = "matches")
public class Match {
    public enum GamePiece {
        NONE,
        CUBE,
        CONE
    }


    @PrimaryKey
    public int uid;

    @ColumnInfo(name = "team_number")
    public int teamNumber;

    @ColumnInfo(name = "match_number")
    public int matchNumber;

    @ColumnInfo(name = "match_type")
    public String matchType;

    public String color;

    @ColumnInfo(name = "color_number")
    public int colorNumber;

//    public int mobility;

    @ColumnInfo(name = "auton_high")
    public int autonHigh;

    @ColumnInfo(name = "auton_middle")
    public int autonMiddle;

    @ColumnInfo(name = "auton_low")
    public int autonLow;

    @ColumnInfo(name = "auton_dropped")
    public int autonDropped;

    @ColumnInfo(name = "auton_charge")
    public int autonCharge;

    @ColumnInfo(name = "teleop_high")
    public int teleopHigh;

    @ColumnInfo(name = "teleop_middle")
    public int teleopMiddle;

    @ColumnInfo(name = "teleop_low")
    public int teleopLow;

//    @ColumnInfo(name = "teleop_dropped")
//    public int teleopDropped;

    @ColumnInfo(name = "teleop_charge")
    public int teleopCharge;

    @ColumnInfo(name = "teleop_park")
    public int teleopPark;

    @ColumnInfo(name = "feed_place_both")
    public int feedPlaceBoth;

    public int coop;

    public int links;

    @NonNull
    @Override
    public String toString() {
        return  "uid: " + uid +
                "\tteam_number" + teamNumber +
                "\tmatch_number" + matchNumber+
                "\tmatch_type" + matchType +
                "\tauton_high" + autonHigh +
                "\tauton_middle" + autonMiddle +
                "\tfeedPlaceBoth" + feedPlaceBoth +
                "\tlinks" + links;
    }
    //

    public String toQRCodeString() {
        return  teamNumber + "," +
                matchNumber+ "," +
                matchType + "," +
                autonHigh + "," +
                autonMiddle + "," +
                autonLow + "," +
                autonDropped + "," +
                autonCharge + "," +
                teleopHigh + "," +
                teleopMiddle + "," +
                teleopLow + "," +
                teleopCharge + "," +
                teleopPark + "," +
                feedPlaceBoth + "," +
                coop + "," +
                links;
    }

    @ColumnInfo(name = "auton_grid_string")
    public String autonGridString;

    @ColumnInfo(name = "teleop_grid_string")
    public String teleopGridString;
    @Ignore
    public GamePiece[][] autonGrid;
    @Ignore
    public GamePiece[][] teleopGrid;

    public void setTeleopGrid(int i, int j, GamePiece gp) {
        this.teleopGrid[i][j] = gp;
        updateGridStrings();
    }

    public void setAutonGrid(int i, int j, GamePiece gp) {
        this.autonGrid[i][j] = gp;
        updateGridStrings();
    }

    public Match() {
        if(autonGridString == null) {
            autonGrid = new GamePiece[3][9];
            nullAutonGrid();
        } else {
            this.generateAutonGridFromString();
        }

        if(teleopGridString == null) {
            teleopGrid = new GamePiece[3][9];
            nullTeleopGrid();
        } else {
            this.generateTeleopGridFromString();
        }
        updateGridStrings();
    }

    public void generateTeleopGridFromString() {
        String[] strs = teleopGridString.split(",");
        for(int i = 0; i < teleopGrid.length; i++) {
            for(int j = 0; j < teleopGrid[0].length; j++) {
                Log.d("gamepiece", "i: " + i + "j: " + j + " == " + strs[i * teleopGrid[0].length + j]);
                teleopGrid[i][j] = Match.gamePieceFromString(strs[i * teleopGrid[0].length + j]);
            }
        }
    }
    public void generateAutonGridFromString() {
        String[] strs = autonGridString.split(",");
        for(int i = 0; i < autonGrid.length; i++) {
            for(int j = 0; j < autonGrid[0].length; j++) {
                Log.d("gamepiece", "i: " + i + "j: " + j + " == " + strs[i * autonGrid[0].length + j]);
                autonGrid[i][j] = Match.gamePieceFromString(strs[i * autonGrid[0].length + j]);
            }
        }
    }

    public void nullAutonGrid() {
        for(int i = 0; i < autonGrid.length; i++) {
            for (int j = 0; j < autonGrid[0].length; j++) {
                if(autonGrid[i][j] == null) {
                    autonGrid[i][j] = GamePiece.NONE;
                    Log.d("AutonGrid", autonGrid[i][j].toString());
                }
            }
        }
    }

    public void nullTeleopGrid() {
        for(int i = 0; i < teleopGrid.length; i++) {
            for (int j = 0; j < teleopGrid[0].length; j++) {
                if(teleopGrid[i][j] == null) {
                    teleopGrid[i][j] = GamePiece.NONE;
                    Log.d("TeleopGrid", teleopGrid[i][j].toString());
                }
            }
        }
    }


    public void updateGridStrings() {
        autonGridString = "";
        for(GamePiece[] array : autonGrid) {
            for (GamePiece gp : array) {
                switch(gp) {
                    case NONE:
                        autonGridString += "NONE,";
                        break;
                    case CONE:
                        autonGridString += "CONE,";
                        break;
                    case CUBE:
                        autonGridString += "CUBE,";
                        break;
                }
            }
        }
        teleopGridString = "";
        for(GamePiece[] array : teleopGrid) {
            for (GamePiece gp : array) {
                switch(gp) {
                    case NONE:
                        teleopGridString += "NONE,";
                        break;
                    case CONE:
                        teleopGridString += "CONE,";
                        break;
                    case CUBE:
                        teleopGridString += "CUBE,";
                        break;
                }
            }
        }
    }


    public static GamePiece gamePieceFromString(String s) {
        if (s.equals("CONE")) {
            return GamePiece.CONE;
        }
        else if (s.equals("CUBE")) {
            return GamePiece.CUBE;
        }
        else {
            return GamePiece.NONE;
        }
    }
}
