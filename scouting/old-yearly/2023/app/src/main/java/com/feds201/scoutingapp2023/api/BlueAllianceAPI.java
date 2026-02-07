package com.feds201.scoutingapp2023.api;

import static com.feds201.scoutingapp2023.api.JSONRequest.getParamsString;
import static com.feds201.scoutingapp2023.api.JSONRequest.sendGetRequest;

import android.content.SharedPreferences;
import android.util.Log;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.HashMap;

public class BlueAllianceAPI {
    public static final String BLUE_ALLIANCE_API_URI = "https://www.thebluealliance.com/api/v3/";
    /**
     * Calls the Blue Alliance API URL with the eventCode to get information about the matches at that event.
     *
     * @param  eventCode    The event code for that particular event.
     * @param  TBAAuthKey   Your developer authentication key needed to access the Blue Alliance API.
     * @return The JSON string returned by the request.
     */
    public static String RequestMatchesByEventCode(String eventCode, String TBAAuthKey) {
        HashMap<String, String> params = new HashMap<>();
        params.put("X-TBA-Auth-Key", TBAAuthKey);
        String paramsStr = getParamsString(params);
        String getURL = BLUE_ALLIANCE_API_URI + "event/" + eventCode + "/matches?" + paramsStr;
//        //Log.d("json", getURL);
        String getRequest = sendGetRequest(getURL);
//        //Log.d("json", "REQUEST SENT");
        return getRequest;
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

    public static ArrayList<String[]> TeamNumberMatchNumberMatchType(String json, String colorCode) {
        //Log.d("json", colorCode);
        String allianceColor = colorCode.contains("R") ? "red" : "blue";
        int allianceNumber = Integer.parseInt(colorCode.substring(1));
        ArrayList<String[]> allStringsList = new ArrayList<>();

        // TODO: man do i hate how much code is in between the try-catch
        try
        {
            JSONArray ja = new JSONArray(json);
            int numberOfMatches = ja.length();

            for(int i = 0; i < numberOfMatches; i++) {

                String[] sArr = new String[3];

                JSONObject jo = new JSONArray(json).getJSONObject(i);
                String matchType = jo.getString("comp_level");
                String matchNumber = String.valueOf(jo.getInt("match_number"));
                String teamCode = jo.getJSONObject("alliances")
                        .getJSONObject(allianceColor)
                        .getJSONArray("team_keys")
                        .getString(allianceNumber-1);
                String teamNumber = teamCode.substring(3);

                sArr[0] = teamNumber;
                sArr[1] = matchNumber;
                sArr[2] = matchType;

                allStringsList.add(sArr);
            }
            return allStringsList;
        }
        catch (JSONException e)
        {
            e.printStackTrace();
        }
        return null;
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
