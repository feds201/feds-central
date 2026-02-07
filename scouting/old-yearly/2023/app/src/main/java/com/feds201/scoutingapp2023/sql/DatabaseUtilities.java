package com.feds201.scoutingapp2023.sql;

import com.feds201.scoutingapp2023.MainActivity;

import java.util.ArrayList;
import java.util.List;

public class DatabaseUtilities {
    public static ArrayList<String> ListOfAllMatches() {
        MatchDao matchDao = MainActivity.app_db.matchDao();
        List<MatchTuple> matches = matchDao.loadAllMatches();

        ArrayList<String> matchStrings = new ArrayList<>();
        if(matches == null || matches.size() == 0) {
            matchStrings.add("nothing to see here");
            return matchStrings;
        }

        for(MatchTuple mt : matches) {
            matchStrings.add(mt.match_type + " " + mt.match_number);
        }
        return matchStrings;
    }

    public static void TeamNumberMatchNumberMatchTypeColorColorNumberToRow(ArrayList<String[]> teamNumberMatchNumberMatchType, String color, int colorNumber) {
        MatchDao matchDao = MainActivity.app_db.matchDao();

        for(int i = 0; i < teamNumberMatchNumberMatchType.size(); i++) {
            String[] currentMatchString = teamNumberMatchNumberMatchType.get(i);

            if (currentMatchString[2].equals("qm")) { // we only really need to scout qualifying matches :)
                Match m = new Match();
                m.uid = Integer.parseInt(currentMatchString[1]);
                m.teamNumber = Integer.parseInt(currentMatchString[0]);
                m.matchNumber = Integer.parseInt(currentMatchString[1]);
                m.matchType = currentMatchString[2];
                m.color = color;
                m.colorNumber = colorNumber;
                matchDao.insertAll(m);
            }
        }
    }

    public static void DropAllMatches() {
        MatchDao matchDao = MainActivity.app_db.matchDao();

        List<Match> matches = matchDao.getAll();

        for(int i = matches.size() - 1; i >= 0; i--) {
            matchDao.delete(matches.get(i));
        }
    }
}
