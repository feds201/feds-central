package com.sukhesh.scoutingapp;

import android.content.Context;
import android.content.SharedPreferences;
import android.content.res.Configuration;
import android.os.Bundle;
import android.os.SystemClock;
import android.view.LayoutInflater;
import android.view.MenuItem;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.ImageView;
import android.widget.PopupMenu;
import android.widget.TextView;
import android.widget.Toast;

import androidx.appcompat.app.ActionBarDrawerToggle;
import androidx.drawerlayout.widget.DrawerLayout;
import androidx.fragment.app.Fragment;

import androidx.fragment.app.FragmentTransaction;
import androidx.recyclerview.widget.DefaultItemAnimator;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.google.android.material.bottomnavigation.BottomNavigationView;
import com.sukhesh.scoutingapp.storage.JSONStorage;

import org.json.JSONException;


public class Home extends Fragment {
    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        /*
         * Set up the RecyclerView (essentially a list of items) for the list of quals
         */
        // access to this view (see fragment_home.xml)
        View homeView;
        Configuration config = getResources().getConfiguration();
        if (config.smallestScreenWidthDp >= 600) {
            homeView = inflater.inflate(R.layout.fragment_home, container, false);
        } else {
            homeView = inflater.inflate(R.layout.fragment_home_phone, container, false);
        }

        Button btn = homeView.findViewById(R.id.buttonofgreatness);
        btn.setOnClickListener(view -> {
            FragmentTransaction fr = getParentFragmentManager().beginTransaction();
            fr.replace(R.id.body_container, new BlueAlliance());
            fr.commit();
        });

        // access to the view's recycler view object
        RecyclerView qualsList = homeView.findViewById(R.id.rvQuals);
        // set the layout for the recycler
        qualsList.setLayoutManager(new LinearLayoutManager(getActivity()));

        /*
         * Instantiate Match list from quals.xml using Matches object
         */
        // collect the matches from strings.xml
        String[] rawStringValues = getResources().getStringArray(R.array.quals);
        SharedPreferences sp = requireContext().getSharedPreferences("matches", Context.MODE_PRIVATE);

        // if you already loaded the matches, then don't overwrite data
        String rawJSONValue = sp.getString("json", "");
        if (rawJSONValue.equals("")) {
            try {
                JSONStorage.addMatches(sp, rawStringValues);
            } catch (JSONException e) {
                e.printStackTrace();
            }
        }

        /*
         * Set up what happens when a Qual is pressed
         */
        QualsRecyclerViewAdapter qualsAdapter = new QualsRecyclerViewAdapter(getActivity(), JSONStorage.GetListOfMatches(sp));
        // use our adaptor, see QualsRecyclerViewAdapter, to interact with the Quals RecycleView
        qualsList.setAdapter(qualsAdapter);
        qualsList.setItemAnimator(new DefaultItemAnimator());

        qualsAdapter.setClickListener(position -> {
            String matchName = qualsAdapter.getItem(position);
            SharedPreferences.Editor editor = sp.edit();
            editor.putString("currentMatch", matchName);
            editor.apply();

            BottomNavigationView bottomNav = getActivity().findViewById(R.id.bottom_navigation);
            bottomNav.setSelectedItemId(R.id.dashboard);

            FragmentTransaction fr = getParentFragmentManager().beginTransaction();
            fr.replace(R.id.body_container, new RapidReactInput());
            fr.commit();
        });


        return homeView;

    }
}
