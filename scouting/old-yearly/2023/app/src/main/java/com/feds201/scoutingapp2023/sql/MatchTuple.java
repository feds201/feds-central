package com.feds201.scoutingapp2023.sql;

import androidx.room.ColumnInfo;

public class MatchTuple {
    @ColumnInfo(name = "match_type")
    public String match_type;

    @ColumnInfo(name = "match_number")
    public int match_number;
}
