package com.feds201.scoutingapp2023.component;

import android.view.View;
import android.widget.ImageButton;

import androidx.annotation.NonNull;

import com.feds201.scoutingapp2023.R;

import java.lang.reflect.Field;
import java.util.ArrayList;


public class GamePieceButton implements Component {
    public ImageButton button;
    public int imageState = 0;
    private final int buttonId;
    private final String type;

    private final CycleState cycleState;
    private final String buttonIdString;

    public enum ScoreType {
        AUTON_LOW,
        AUTON_MIDDLE,
        AUTON_HIGH,
        TELEOP_LOW,
        TELEOP_MIDDLE,
        TELEOP_HIGH
    }

    public GamePieceButton(int buttonId, String buttonIdString, View view, String type, CycleState cycleState) {
        this.button = view.findViewById(buttonId);
        this.buttonId = buttonId;
        this.type = type;
        this.cycleState = cycleState;
        this.buttonIdString = buttonIdString;
    }

    public ScoreType getScoreType() {
        if(buttonIdString.contains("low")) {
            return buttonIdString.contains("auton") ? ScoreType.AUTON_LOW : ScoreType.TELEOP_LOW;
        } else if(buttonIdString.contains("middle")) {
            return buttonIdString.contains("auton") ? ScoreType.AUTON_MIDDLE : ScoreType.TELEOP_MIDDLE;
        } else if(buttonIdString.contains("high")) {
            return buttonIdString.contains("auton") ? ScoreType.AUTON_HIGH : ScoreType.TELEOP_HIGH;
        }
        return null;
    }

    public int getRowFromScoreType(ScoreType st) {
        switch (st) {
            case AUTON_LOW:      case TELEOP_LOW:    return 2;
            case AUTON_MIDDLE:   case TELEOP_MIDDLE: return 1;
            case AUTON_HIGH:     case TELEOP_HIGH:   return 0;
        }
        return -1;
    }


    public static ArrayList<GamePieceButton> generateCyclingButtonsFromPrefix(Class resClass, String prefix, View view) {
        java.lang.reflect.Field[] fields = resClass.getFields();
        ArrayList<GamePieceButton> buttons = new ArrayList<>();

        for (Field field : fields) {
            if (field.getName().contains(prefix)) {
                try {
                    int id = field.getInt(resClass);
                    CycleState cycleState = findCycleState(field.getName());
                    GamePieceButton button = new GamePieceButton(id, field.getName(), view, prefix, cycleState);
                    buttons.add(button);
                } catch (IllegalAccessException e) {
                    throw new RuntimeException(e);
                }
            }
        }

        return buttons;
    }

    public int getColNum() {
        String lastChar = buttonIdString.substring( buttonIdString.length() - 1);
        int lastCharNum = Integer.parseInt(lastChar);
        return lastCharNum;
    }

    public int getButtonId() { return buttonId; }

//    public void cycleImageAll() {
//        this.imageState++;
//        switch(this.imageState) {
//            case 1:
//                this.button.setImageResource(R.drawable.cone);
//                break;
//            case 2:
//                this.button.setImageResource(R.drawable.cube);
//                break;
//            case 3:
//                this.button.setImageResource(R.drawable.nothing);
//                this.imageState = 0;
//                break;
//        }
//    }

    public CycleState getCycleState() { return this.cycleState; }

    public static CycleState findCycleState(String fieldName) {
        String lastChar = fieldName.substring(fieldName.length()-1);
        int lastNum = Integer.parseInt(lastChar);
        if (fieldName.contains("low"))
            return CycleState.BOTH;
        else{
            switch (lastNum) {
                case 1: case 3: case 4: case 6: case 7: case 9: return CycleState.CONE;
                default: return CycleState.CUBE;
            }
        }
    }


    @NonNull
    public String toString() {
        return this.type + " with id " + this.buttonId;
    }


    public enum CycleState {
        CUBE,
        CONE,
        BOTH
    }
}