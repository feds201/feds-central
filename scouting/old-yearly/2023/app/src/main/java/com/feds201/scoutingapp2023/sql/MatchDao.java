package com.feds201.scoutingapp2023.sql;


import androidx.room.Dao;
import androidx.room.Delete;
import androidx.room.Insert;
import androidx.room.Query;
import androidx.room.Update;

import java.util.List;

@Dao
public interface MatchDao {
    @Query("SELECT * FROM matches")
    List<Match> getAll();

    @Query("SELECT * FROM matches WHERE uid IN (:userIds)")
    List<Match> loadAllByIds(int[] userIds);

    @Query("SELECT match_type, match_number FROM matches")
    List<MatchTuple> loadAllMatches();

//    @Query("SELECT * FROM matches WHERE first_name LIKE :first AND " +
//            "last_name LIKE :last LIMIT 1")
//    Match findByName(String first, String last);

    @Insert
    void insertAll(Match... match);

    @Delete
    void delete(Match match);


    @Update
    void update(Match match);
}
