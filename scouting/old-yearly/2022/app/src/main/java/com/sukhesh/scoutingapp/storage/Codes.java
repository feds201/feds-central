package com.sukhesh.scoutingapp.storage;

import java.util.ArrayList;

public class Codes {
    public ArrayList<String[]> codes;

    private final int CODE = 0;
    private final int PROPERTY_NAME = 1;

    Codes(String[] rawCodeData) {
        this.codes = new ArrayList<>();
        for(String s: rawCodeData) {
            this.codes.add(s.split(","));
        }
    }

    public String findCode(String propertyName) {
        for(String[] row: this.codes) {
            if(row[PROPERTY_NAME].equals(propertyName)) {
                return row[CODE];
            }
        }
        return "";
    }

    public String decodeCode(String code) {
        for(String[] row: this.codes){
            if(row[CODE].equals(code)) {
                return row[PROPERTY_NAME];
            }
        }
        return "";
    }

    public String findType(String s) {
        boolean isCode = this.isCode(s);
        for (String[] row: this.codes) {
            int TYPE = 2;
            if(isCode) {
                if (row[CODE].equals(s)) {
                    return row[TYPE];
                }
            } else {
                if (row[PROPERTY_NAME].equals(s)) {
                    return row[TYPE];
                }
            }
        }
        return "";
    }

    private boolean isCode(String s) {
        if(s.length() != 2) return false;
        return Character.isUpperCase(s.charAt(0)) && Character.isUpperCase(s.charAt(1));
    }
}
