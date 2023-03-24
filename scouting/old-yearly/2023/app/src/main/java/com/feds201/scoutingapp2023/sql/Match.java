package com.feds201.scoutingapp2023.sql;


import androidx.annotation.NonNull;
import androidx.room.ColumnInfo;
import androidx.room.Entity;
import androidx.room.Ignore;
import androidx.room.PrimaryKey;

import org.json.JSONObject;

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

    @Ignore
    public GamePiece[][] grid = new GamePiece[3][9];
}
