package com.feds201.scoutingapp2023;

import android.os.Bundle;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.view.animation.Animation;
import android.widget.Toast;

import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;
import androidx.fragment.app.FragmentTransaction;
import androidx.recyclerview.widget.DefaultItemAnimator;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.feds201.scoutingapp2023.api.BlueAllianceAPI;
import com.feds201.scoutingapp2023.sql.DatabaseUtilities;
import com.feds201.scoutingapp2023.sql.Match;
import com.feds201.scoutingapp2023.sql.MatchDao;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Comparator;
import java.util.List;


public class Home extends Fragment {
    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        View homeView = inflater.inflate(R.layout.fragment_home_tablet, container, false);

        ArrayList<String> matchesStrings = DatabaseUtilities.ListOfAllMatches();

        try {
            Thread.sleep(1 * 1000);
        } catch (InterruptedException e) {
            throw new RuntimeException(e);
        }

        if(matchesStrings.size() != 1) {
            matchesStrings.sort(new SortNumerically());
        }

        StringBuilder printStr = new StringBuilder();
        for(String s : matchesStrings) {
            printStr.append(s).append(",");
            Log.d("matches", printStr.toString());
        }

        RecyclerView qualsList = homeView.findViewById(R.id.rvQuals);
        qualsList.setLayoutManager(new LinearLayoutManager(getActivity()));
        QualsRecyclerViewAdapter qualsAdapter = new QualsRecyclerViewAdapter(getActivity(), matchesStrings);
        qualsList.setAdapter(qualsAdapter);
        qualsList.setItemAnimator(new DefaultItemAnimator());

        qualsAdapter.setClickListener(position -> {
            MatchDao matchDao = MainActivity.app_db.matchDao();
            int[] positions = new int[1];
            positions[0] = position;

            List<Match> matches = matchDao.loadAllByIds(positions);

            Input.currentMatch = matches.get(0);

            FragmentTransaction fr = getParentFragmentManager().beginTransaction();
            fr.replace(R.id.body_container, new Input());
            fr.commit();
        });

        return homeView;
    }


    static class SortNumerically implements Comparator<String> {
        public int compare (String a, String b) {
            int aInt = Integer.parseInt(a.substring(a.indexOf(" ") + 1));
            int bInt = Integer.parseInt(b.substring(b.indexOf(" ") + 1));

            return aInt - bInt;
        }
    }
}
