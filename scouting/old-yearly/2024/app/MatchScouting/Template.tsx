import React, { useState } from "react";
import { Text, View, StyleSheet, TouchableOpacity } from "react-native";
import DraggableFlatList, {
    ScaleDecorator,
    RenderItemParams,
} from "react-native-draggable-flatlist";

import { mapIndexToData, Item } from "./util"

const NUM_ITEMS = 10;

const initialData: Item[] = [...Array(NUM_ITEMS)].map(mapIndexToData);

export default function Basic() {
    const [data, setData] = useState(initialData);

    const renderItem = ({ item, drag, isActive }: RenderItemParams<Item>) => {
        return (
            <ScaleDecorator>
                <TouchableOpacity
                    activeOpacity={1}
                    onLongPress={drag}
                    disabled={isActive}
                    style={[
                        styles.rowItem,
                        { backgroundColor: isActive ? "red" : item.backgroundColor },
                    ]}
                >
                    <Text style={styles.text}>{item.text}</Text>
                </TouchableOpacity>
            </ScaleDecorator>
        );
    };

    return (
        <DraggableFlatList
            data={data}
            onDragEnd={({ data }) => setData(data)}
            keyExtractor={(item) => item.key}
            renderItem={renderItem}
        />
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
    },
});