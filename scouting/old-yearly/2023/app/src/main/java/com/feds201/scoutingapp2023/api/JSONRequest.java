package com.feds201.scoutingapp2023.api;

import android.util.Log;

import java.io.IOException;
import java.util.Map;

import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.Response;

public class JSONRequest {
    public static String sendGetRequest(String url) {
        OkHttpClient client = new OkHttpClient();

        Request request = new Request.Builder()
                .url(url)
                .build();

        //Log.d("json", "In sendGetRequest method");

        try (Response response = client.newCall(request).execute()) {
            //Log.d("json", "In request OK!");
            //Log.d("json", url);
            return response.body().string();
        } catch (IOException e) {
            e.printStackTrace();
        }

        //Log.d("json", "Nothing was returned by the request.");
        return "";
    }

    public static String getParamsString(Map<String, String> paramsMap) {
        StringBuilder result = new StringBuilder();

        for (Map.Entry<String, String> entry : paramsMap.entrySet()) {
            result.append(entry.getKey());
            result.append("=");
            result.append(entry.getValue());
            result.append("&");
        }

        String resultString = result.toString();
        return resultString.length() > 0
                ? resultString.substring(0, resultString.length() - 1)
                : resultString;
    }
}
