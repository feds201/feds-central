package com.sukhesh.scoutingapp.storage;

import android.content.SharedPreferences;
import android.util.Log;

import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.Iterator;

public class JSONStorage {
    public JSONObject jo;
    SharedPreferences spContext;

    public JSONStorage(SharedPreferences sp) {
        JSONObject j = new JSONObject();
        this.spContext = sp;
        String rawJSONData = sp.getString("json", "");
        if (rawJSONData.equals("")) {
            jo = new JSONObject();
        } else {
            try {
                jo = new JSONObject(rawJSONData);
            } catch (JSONException e) {
                e.printStackTrace();
            }
        }
    }

    public static void addMatches(SharedPreferences sp, String[] rawMatchList) throws JSONException {
        JSONObject jo = new JSONObject();
        for (String value : rawMatchList) {
            try {
                String[] s = value.split(",");
                String match = s[0] + s[1];
                JSONObject j = new JSONObject();
                j.put("matchType", s[0]);
                j.put("matchNumber", Integer.parseInt(s[1]));
                j.put("teamNumber", Integer.parseInt(s[2]));
                j.put("robotAllianceInfo", s[3]);
                jo.put(match, j);
            }
            catch (Error error) {
                return; // don't do it if its buggy!!!!!
            }
        }
        SharedPreferences.Editor spEditor = sp.edit();
        spEditor.putString("json", jo.toString());
        spEditor.apply();
    }
    public static void appendMatches(SharedPreferences sp, String[] rawMatchList) throws JSONException {
        String jsonString = sp.getString("json", null);
        if (jsonString == null) {
            return;
        }
        JSONObject jo = new JSONObject(jsonString);

        for (String value : rawMatchList) {
            String[] s = value.split(",");
            String match = s[0] + s[1];
            JSONObject j = new JSONObject();
            j.put("matchType", s[0]);
            j.put("matchNumber", Integer.parseInt(s[1]));
            j.put("teamNumber", Integer.parseInt(s[2]));
            j.put("robotAllianceInfo", s[3]);
            jo.put(match, j);
        }

        SharedPreferences.Editor spEditor = sp.edit();
        spEditor.putString("json", jo.toString());
        spEditor.apply();
    }

    public static boolean validateJSONStrings(String[] strs) {
        for(String s: strs) {
           if(!validateJSONString(s)) {
               return false;
           }
        }
        return true;
    }

    public static boolean validateJSONString(String s) {
        if(s.indexOf(',') == -1) {
            return false;
        }

        String[] fields = s.split(",");

        if(fields.length != 4) {
            return false;
        }

        String matchType = fields[0];
        String matchNumber = fields[1];
        String teamNumber = fields[2];
        String colorCode = fields[3];

        if (matchType.length() < 1 || !(matchType.equals("Q") || matchType.equals("QF") || matchType.equals("SF") || matchType.equals("EF") || matchType.equals("F"))) {
            return false;
        }
        if (matchNumber.length() < 1 || !matchNumber.matches("[0-9]+")) {
            return false;
        }
        if (teamNumber.length() < 1 || !matchNumber.matches("[0-9]+")) {
            return false;
        }
        if(colorCode.length() != 2 || !(colorCode.equals("R1") || colorCode.equals("R2") || colorCode.equals("R3") || colorCode.equals("B1") || colorCode.equals("B2") || colorCode.equals("B3"))) {
            return false;
        }
        return true;
    }


    public static ArrayList<String> GetListOfMatches(SharedPreferences sp) {
        JSONStorage js = new JSONStorage(sp);
        ArrayList<String> s = new ArrayList<>();
        Iterator<String> it = js.jo.keys();
        while (it.hasNext()) {
            s.add(it.next());
        }
        return s;
    }

    public String getString(String matchName, String name) {
        JSONObject matchStorage = (JSONObject) this.jo.opt(matchName);
        return matchStorage.optString(name);
    }

    public int getInt(String matchName, String name) {
        JSONObject matchStorage = (JSONObject) this.jo.opt(matchName);
        return matchStorage.optInt(name);
    }
    public boolean getBoolean(String matchName, String name) {
        JSONObject matchStorage = (JSONObject) this.jo.opt(matchName);
        return matchStorage.optBoolean(name);
    }

    public void add(String match, String name, int value) {
        try {
            JSONObject j = (JSONObject) this.jo.get(match);
            j.put(name, value);
            this.jo.put(match, j);
            this.store();
        } catch (JSONException e) {
            e.printStackTrace();
        }
    }

    public void add(String match, String name, String value) {
        try {
            JSONObject j = (JSONObject) this.jo.get(match);
            j.put(name, value);
            this.jo.put(match, j);
            this.store();
        } catch (JSONException e) {
            e.printStackTrace();
        }
    }

    public void add(String match, String name, boolean value) {
        try {
            JSONObject j = (JSONObject) this.jo.get(match);
            j.put(name, value);
            this.jo.put(match, j);
            this.store();
        } catch (JSONException e) {
            e.printStackTrace();
        }
    }

    public void add(String match, String name, long value) {
        try {
            JSONObject j = (JSONObject) this.jo.get(match);
            j.put(name, value);
            this.jo.put(match, j);
            this.store();
        } catch (JSONException e) {
            e.printStackTrace();
        }
    }

    public String makeQuickDebugString(String matchName) { //not to be used legitly :)
        JSONObject match = (JSONObject) this.jo.opt(matchName);
        Iterator<String> keys = match.keys();
        String returnString = "";
        while(keys.hasNext()) {
            String key = keys.next();
            returnString += key;
            returnString += match.opt(key);
            returnString += "$";
        }
        return returnString;
    }

    public String makeCitrusCircuitsStyleString(String matchName, String[] rawCodes) {
        Codes codes = new Codes(rawCodes);
        JSONObject match = (JSONObject) this.jo.opt(matchName);

        Iterator<String> keys = match.keys();
        String returnString = "";
        while(keys.hasNext()) {
            String key = keys.next();
            returnString += codes.findCode(key);
            returnString += match.opt(key);
            returnString += "$";
        }
        return returnString;
    }

    private void store() {
        SharedPreferences.Editor spEditor = this.spContext.edit();
        spEditor.putString("json", this.jo.toString());
        spEditor.apply();
    }
}