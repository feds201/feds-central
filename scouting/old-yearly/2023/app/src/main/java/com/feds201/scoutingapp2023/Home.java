package com.feds201.scoutingapp2023;

import android.content.SharedPreferences;
import android.content.res.Configuration;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;

import androidx.fragment.app.Fragment;
import androidx.fragment.app.FragmentTransaction;
import androidx.recyclerview.widget.DefaultItemAnimator;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import java.util.ArrayList;


public class Home extends Fragment {
    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        Configuration config = getResources().getConfiguration();
        View homeView = inflater.inflate(R.layout.fragment_home_tablet, container, false);

        RecyclerView qualsList = homeView.findViewById(R.id.rvQuals);
        qualsList.setLayoutManager(new LinearLayoutManager(getActivity()));
        ArrayList<String> forQualsAdapter = new ArrayList<>();
        forQualsAdapter.add("Joe");
        forQualsAdapter.add("Hello");
        forQualsAdapter.add("Hello");
        forQualsAdapter.add("Hello");
        forQualsAdapter.add("Hello");
        forQualsAdapter.add("Hello");
        QualsRecyclerViewAdapter qualsAdapter = new QualsRecyclerViewAdapter(getActivity(), forQualsAdapter);
        qualsList.setAdapter(qualsAdapter);
        qualsList.setItemAnimator(new DefaultItemAnimator());

        /*qualsAdapter.setClickListener(position -> {
            String matchName = qualsAdapter.getItem(position);
            SharedPreferences.Editor editor = sp.edit();
            editor.putString("currentMatch", matchName);
            editor.apply();

            FragmentTransaction fr = getParentFragmentManager().beginTransaction();
            fr.replace(R.id.body_container, new RapidReactInput());
            fr.commit();
        });
         */

        return homeView;
    }
}
