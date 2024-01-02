import React, { useState } from "react";
import {Text, StyleSheet, TouchableOpacity, View, Animated, ScrollView} from "react-native";
import DraggableFlatList, {ScaleDecorator, RenderItemParams} from "react-native-draggable-flatlist";
import { mapIndexToData, Item } from "./util"
import Icon from "react-native-vector-icons/FontAwesome";
import FloatingButton from "../../components/FloatingButton";

const initialData: Item[] = [...Array(20)].map(mapIndexToData);

export default function Basic() {
    const [data, setData] = useState(initialData);

    const renderItem = ({ item, drag, isActive }: RenderItemParams<Item>) => {
        return (
            <ScaleDecorator>
                <TouchableOpacity activeOpacity={1} onLongPress={drag} disabled={isActive} style={{backgroundColor: "#000", height: 60, justifyContent: "center"}}>
                    <Text style={styles.text}>{item.key}</Text>
                </TouchableOpacity>
            </ScaleDecorator>
        );
    };

    return (
        <View style={{backgroundColor: "#000"}}>
                    <DraggableFlatList
                        data={data}
                        onDragEnd={({ data }) => setData(data)}
                        keyExtractor={(item) => item.key}
                        renderItem={renderItem}
                    />
                <View>
                    <FloatingButton/>
                </View>
        </View>
    );
}

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