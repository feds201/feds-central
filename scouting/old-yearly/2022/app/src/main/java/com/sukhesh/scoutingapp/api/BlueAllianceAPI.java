package com.sukhesh.scoutingapp.api;

import static com.sukhesh.scoutingapp.api.JSONRequest.getParamsString;
import static com.sukhesh.scoutingapp.api.JSONRequest.sendGetRequest;

import android.content.SharedPreferences;
import android.util.Log;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.HashMap;

public class BlueAllianceAPI {

    //TODO: does this really need to be public and final?
    public static final String BLUE_ALLIANCE_API_URI = "https://www.thebluealliance.com/api/v3/";


    /**
     * Calls the Blue Alliance API URL with the eventCode to get information about the matches at that event.
     *
     * @param  eventCode    The event code for that particular event.
     * @param  TBAAuthKey   Your developer authentication key needed to access the Blue Alliance API.
     * @return The JSON string returned by the request.
     */
    public static String RequestMatchesByEventCode(String eventCode, String TBAAuthKey) {
        /*
            NOTE: This method is separate from the others as it is the only function that requires
                  use of the internet. As we want the app to rely on the internet as least as
                  possible, the rest of the functions can be used with or without the internet
         */
        // TODO: could we generalize this even more?
        HashMap<String, String> params = new HashMap<>();
        params.put("X-TBA-Auth-Key", TBAAuthKey);
        String paramsStr = getParamsString(params);
        String getURL = BLUE_ALLIANCE_API_URI + "event/" + eventCode + "/matches?" + paramsStr;
        String getRequest = sendGetRequest(getURL);
        return getRequest;
    }

    public static void SendRawMatchesToSharedPreferences(SharedPreferences sp, String rawMatches) {
        sp.edit().putString("rawMatches", rawMatches).apply();
    }

    public static String GetRawMatchesFromSharedPreferences(SharedPreferences sp) {
        return sp.getString("rawMatches", "");
    }

    public static void SendColorCodeToSharedPreferences(SharedPreferences sp, String colorCode) {
        sp.edit().putString("colorCode", colorCode).apply();
    }

    public static String GetColorCodeFromSharedPreferences(SharedPreferences sp) {
        return sp.getString("colorCode", "R1");
    }

    public static void SendEventCodeToSharedPreferences(SharedPreferences sp, String eventCode) {
        sp.edit().putString("eventCode", eventCode).apply();
    }

    public static String GetEventCodeFromSharedPreferences(SharedPreferences sp) {
        return sp.getString("eventCode", "2015arc");
    }

    public static String[] returnMatchListFromRequestString(String json, String colorCode, String[] qualsString) {
        String allianceColor = colorCode.charAt(0) == 'R' ? "red" : "blue";
        int allianceNumber = Integer.parseInt(colorCode.substring(1));
        String[] matches;

        // TODO: man do i hate how much code is in between the try-catch
        try
        {
            JSONArray ja = new JSONArray(json);
            int numberOfMatches = ja.length();
            matches = new String[numberOfMatches];

            for(int i = 0; i < numberOfMatches; i++) {
                JSONObject jo = new JSONArray(json).getJSONObject(i);
                String matchType = myMatchTypeFromTBAMatchType(jo.getString("comp_level"));
                String matchNumber = String.valueOf(jo.getInt("match_number"));
                String teamCode = jo.getJSONObject("alliances")
                        .getJSONObject(allianceColor)
                        .getJSONArray("team_keys")
                        .getString(allianceNumber-1);
                String teamNumber = teamCode.substring(3);
                matches[i] = matchType + "," + matchNumber + "," + teamNumber + "," + colorCode;
            }
            return matches;
        }
        catch (JSONException e)
        {
            e.printStackTrace();
        }
        return qualsString;
    }

    /**
     * Helper function to convert the TBA match type, see <a href="https://www.thebluealliance.com/apidocs/v3">the api docs under match at the bottom</a> to my type.
     * @param matchTypeTBA The match type in TBA's format.
     * @return The match type in my format.
     */
    private static String myMatchTypeFromTBAMatchType(String matchTypeTBA) {
        String matchType = "";
        switch (matchTypeTBA) {
            case "qm": matchType = "Q"; break;
            case "qf": matchType = "QF"; break;
            case "sf": matchType = "SF"; break;
            case "f": matchType = "F"; break;
            case "ef": matchType = "EF"; break;
        }
        return matchType;
    }

}
