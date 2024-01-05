import { RenderItemParams, ScaleDecorator } from "react-native-draggable-flatlist";
import { Item } from "../app/MatchScouting/TemplateEditor";
import {StyleSheet, Text, TextInput, TouchableOpacity, View} from "react-native";
import React, {useRef, useState} from "react";
import {Button, CheckBox, Dialog, Slider} from "@rneui/base";
import StopwatchTimer, {StopwatchTimerMethods} from "react-native-animated-stopwatch-timer";

export const componentsView = ({ item, drag, isActive }: RenderItemParams<Item>) => {

    const[plusminusView, setPlusMinusView] = useState(0);
    const[checked, setChecked] = useState(false);
    const stopwatchTimerRef = useRef<StopwatchTimerMethods>(null);
    const[value, setValue] = useState(0);
    const[dialog, setDialog] = useState(false);
    const[minValue, setMinValue] = useState(0);
    const [step, setStep] = useState(0);
    const[maxValue, setMaxValue] = useState(0);

    if(item.text == "header") {
        return (
            <ScaleDecorator>
                <TouchableOpacity activeOpacity={1} onLongPress={drag} disabled={isActive} style={{backgroundColor: "#FFFAFA", height: 60, justifyContent: "center", alignItems: "center"}}>
                    <TextInput placeholder={"Header Title"}/>
                </TouchableOpacity>
            </ScaleDecorator>
        );
    } else if(item.text == "plusminus") {
        return (
            <ScaleDecorator>
                <TouchableOpacity activeOpacity={1} onLongPress={drag} disabled={isActive} style={{backgroundColor: "#FFFAFA", height: 100, alignItems: "flex-start", flex: 1, flexDirection: "row", flexWrap: "wrap", alignContent:"center"}}>
                    <TextInput placeholder={"Title"} textAlign={"center"}  style={{marginLeft: 5, width: 100}}/>
                    <Button title={"+"} buttonStyle={{borderRadius: 30}} containerStyle={{width: 60, marginLeft: 50}} onPress={() => setPlusMinusView(plusminusView + 1)}/>
                    <Text id={item.key} style={{marginLeft: 20}}>{plusminusView}</Text>
                    <Button title={"-"} buttonStyle={{borderRadius: 30}} containerStyle={{width: 60, marginLeft: 20}} onPress={() => setPlusMinusView(plusminusView - 1)}/>
                </TouchableOpacity>
            </ScaleDecorator>
        );
    } else if(item.text == "checkbox") {
        return (
            <ScaleDecorator>
                <TouchableOpacity activeOpacity={1} onLongPress={drag} disabled={isActive} style={{backgroundColor: "#FFFAFA", height: 100, alignItems: "flex-start", flex: 1, flexDirection: "row", flexWrap: "wrap", alignContent:"center"}}>
                    <CheckBox checked={checked} onPress={() => setChecked(!checked)}/>
                    <TextInput placeholder={"Title"} textAlign={"center"}  style={{marginLeft: 5, width: 100}}/>
                </TouchableOpacity>
            </ScaleDecorator>
        );


    } else if (item.text == "stopwatch") {
        return (
            <ScaleDecorator>
                <TouchableOpacity activeOpacity={1} onLongPress={drag} disabled={isActive} style={{backgroundColor: "#FFFAFA", height: 100, alignItems: "flex-start", flex: 1, flexDirection: "row", flexWrap: "wrap", alignContent:"center"}}>
                    <TextInput placeholder={"Title"} textAlign={"center"}  style={{marginLeft: 5, width: 100}}/>
                    <StopwatchTimer ref={stopwatchTimerRef}/>
                    <Button title={"Start"} buttonStyle={{borderRadius: 30}} containerStyle={{marginLeft: 10}} onPress={() => stopwatchTimerRef.current?.play()}/>
                    <Button title={"Pause"} buttonStyle={{borderRadius: 30}} containerStyle={{marginLeft: 0}} onPress={() => stopwatchTimerRef.current?.pause()}/>
                    <Button title={"Reset"} buttonStyle={{borderRadius: 30}} containerStyle={{marginLeft: 0}} onPress={() => stopwatchTimerRef.current?.reset()}/>
                </TouchableOpacity>
            </ScaleDecorator>
        );
    } else if (item.text == "notes") {
        return (
            <ScaleDecorator>
                <TouchableOpacity activeOpacity={1} onLongPress={drag} disabled={isActive} style={{backgroundColor: "#FFFAFA", height: 100, flex: 1, alignContent:"center", alignItems: "center"}}>
                    <TextInput placeholder={"Title"} textAlign={"center"}  style={{width: 100}}/>
                    <TextInput placeholder={"Notes"} style={{marginTop: 10}}/>
                </TouchableOpacity>
            </ScaleDecorator>
        );
    } else if (item.text == "slider") {
        return (
            <ScaleDecorator>
                <TouchableOpacity activeOpacity={1} onLongPress={drag} disabled={isActive} style={{backgroundColor: "#FFFAFA", height: 100, alignItems: "flex-start", flex: 1, flexDirection: "row", flexWrap: "wrap", alignContent:"center"}}>
                    <TextInput placeholder={"Title"} textAlign={"center"}  style={{marginLeft: 5, width: 100}}/>
                    <View style={{ flex: 1, alignItems: 'stretch', justifyContent: 'center' }}>
                        <Slider minimumValue={minValue} step={step} maximumValue={maxValue} thumbTintColor={"#4287f5"} style={{marginRight: 40}} value={value} onValueChange={(value) => setValue(value)}/>
                        <Text>Value: {value}</Text>
                    </View>
                    <Button title={"Options"} onPress={() => setDialog(true)}/>
                </TouchableOpacity>
                <Dialog overlayStyle={{backgroundColor: "#fff"}} isVisible={dialog} onBackdropPress={() => setDialog(!dialog)}>
                    <Dialog.Title title="Options"/>
                    <Dialog.Actions>
                        <TextInput placeholder={"MIN VALUE"} onChangeText={(value) => setMinValue(parseInt(value))}/>
                        <TextInput placeholder={"STEP VALUE"} onChangeText={(value) => setStep(parseInt(value))}/>
                        <TextInput placeholder={"MAX VALUE"} onChangeText={(value) => setMaxValue(parseInt(value))}/>
                        <Button title={"Submit"} onPress={() => setDialog(false)}/>
                    </Dialog.Actions>
                </Dialog>
            </ScaleDecorator>
        );
    }
    else {
        return (
            <ScaleDecorator>
                <TouchableOpacity activeOpacity={1} onLongPress={drag} disabled={isActive} style={{backgroundColor: "#000", height: 0, justifyContent: "center"}}>
                    <Text style={styles.text}>{item.key}</Text>
                </TouchableOpacity>
            </ScaleDecorator>
        );
    }
};

const styles = StyleSheet.create({
    rowItem: {
        height: 100,
        alignItems: "center",
        justifyContent: "center",
    },
    text: {
        color: "white",
        fontSize: 24,
        fontWeight: "bold",
        textAlign: "center",
        justifyContent: "center"
    },
});