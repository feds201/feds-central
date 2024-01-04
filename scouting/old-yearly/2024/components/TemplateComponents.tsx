import {RenderItemParams, ScaleDecorator} from "react-native-draggable-flatlist";
import {Item} from "./itemType";
import {StyleSheet, Text, TextInput, TouchableOpacity} from "react-native";
import React, {useState} from "react";
import {Button, CheckBox} from "@rneui/base";

export const componentsView = ({ item, drag, isActive }: RenderItemParams<Item>) => {

    const[plusminusView, setPlusMinusView] = useState(0);

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
                    <TextInput placeholder={"Title"} textAlign={"center"}  style={{marginLeft: 5, width: 100}}/>
                    <CheckBox checked={false}/>
                </TouchableOpacity>
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