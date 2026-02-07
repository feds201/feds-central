package com.sukhesh.scoutingapp.storage;

import android.util.Log;

import java.util.Comparator;
import java.util.*;

public class MatchComparator {
    public static ArrayList<String> extractMatchTypeSorted(ArrayList<String> arr, String matchType) {

        ArrayList<String> onlyMatchType = new ArrayList<>();
        for(String s: arr) {
            if(s.contains(matchType)) {
                String nums = s.substring(matchType.length());
                if(nums.matches("[0-9]+")) {
                    onlyMatchType.add(nums);
                }
            }
        }
        onlyMatchType.sort(Comparator.comparing(Integer::valueOf));
        for(int i = onlyMatchType.size()-1; i >= 0; i--) {
            String newVal = matchType + onlyMatchType.get(i);
            onlyMatchType.remove(i);
            onlyMatchType.add(i, newVal);
        }
        return onlyMatchType;
    }


//    ArrayList<String> quarterFinals = new ArrayList<String>();
//    ArrayList<String> semiFinals = new ArrayList<String>();
//    ArrayList<String> Finals = new ArrayList<String>();
//    ArrayList<String> quals = new ArrayList<String>();
//        for (int i = 0; i < list.size(); i++) {
//        if(list.get(i).contains("QF")) {
//            quarterFinals.add(list.get(i));
//        } else if(list.get(i).contains("SF")) {
//            semiFinals.add(list.get(i));
//        } else if(list.get(i).contains("F")) {
//            Finals.add(list.get(i));
//        } else {
//            quals.add(list.get(i));
//        }
//    }
//
//    //QUALS SORTER
//
//    ArrayList<String> tot = new ArrayList<String>();
//    ArrayList<String> tempo = new ArrayList<String>();
//        tot.addAll(quals);
//    int size = tot.size();
//        for (int i = 0; i < size; i++) {
//        StringBuilder builder = new StringBuilder();
//        String temp = tot.get(i);
//        builder.append(temp);
//        builder.replace(0, 1, "");
//        tempo.add(builder.toString());
//    }
//        tot.clear();
//        Collections.sort(tempo, Comparator.comparing(Integer::valueOf));
//        for (int i = 0; i < size; i++) {
//        StringBuilder builder = new StringBuilder();
//        String temp = tempo.get(i);
//        builder.append(temp);
//        builder.insert(0, "Q");
//        tot.add(builder.toString());
//    }
//
//    //QUARTER FINALS
//
//    ArrayList<String> tot2 = new ArrayList<String>();
//    ArrayList<String> tempo2 = new ArrayList<String>();
//        tot2.addAll(quarterFinals);
//    int size2 = tot2.size();
//        for (int i = 0; i < size2; i++) {
//        StringBuilder builder = new StringBuilder();
//        String temp = tot2.get(i);
//        builder.append(temp);
//        builder.replace(0, 2, "");
//        tempo2.add(builder.toString());
//    }
//        tot2.clear();
//        Collections.sort(tempo2, Comparator.comparing(Integer::valueOf));
//        for (int i = 0; i < size2; i++) {
//        StringBuilder builder = new StringBuilder();
//        String temp = tempo2.get(i);
//        builder.append(temp);
//        builder.insert(0, "QF");
//        tot2.add(builder.toString());
//    }
//
//    //SEMI FINALS
//
//    ArrayList<String> tot3 = new ArrayList<String>();
//    ArrayList<String> tempo3 = new ArrayList<String>();
//        tot3.addAll(quarterFinals);
//    int size3 = tot3.size();
//        for (int i = 0; i < size3; i++) {
//        StringBuilder builder = new StringBuilder();
//        String temp = tot3.get(i);
//        builder.append(temp);
//        builder.replace(0, 2, "");
//        tempo3.add(builder.toString());
//    }
//        tot3.clear();
//        Collections.sort(tempo3, Comparator.comparing(Integer::valueOf));
//        for (int i = 0; i < size3; i++) {
//        StringBuilder builder = new StringBuilder();
//        String temp = tempo3.get(i);
//        builder.append(temp);
//        builder.insert(0, "SF");
//        tot3.add(builder.toString());
//    }
//
//    //FINALS
//
//    ArrayList<String> tot4 = new ArrayList<String>();
//    ArrayList<String> tempo4 = new ArrayList<String>();
//        tot4.addAll(Finals);
//    int size4 = tot4.size();
//        for (int i = 0; i < size4; i++) {
//        StringBuilder builder = new StringBuilder();
//        String temp = tot4.get(i);
//        builder.append(temp);
//        builder.replace(0, 1, "");
//        tempo4.add(builder.toString());
//    }
//        tot4.clear();
//        Collections.sort(tempo4, Comparator.comparing(Integer::valueOf));
//        for (int i = 0; i < size4; i++) {
//        StringBuilder builder = new StringBuilder();
//        String temp = tempo4.get(i);
//        builder.append(temp);
//        builder.insert(0, "F");
//        tot4.add(builder.toString());
//    }
//        list.clear();
//        list.addAll(tot);
//        list.addAll(tot2);
//        list.addAll(tot3);
//        list.addAll(tot4);
//        System.out.println(list);
}
