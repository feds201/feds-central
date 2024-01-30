import { FlatList, Pressable, StyleSheet, Text, View } from "react-native";
import { Item } from "./TemplateEditor";
import React, { useState } from "react";
import { componentsView } from "../../components/TemplateComponents";
import DraggableFlatList from "react-native-draggable-flatlist/src/components/DraggableFlatList";
import { Button } from "@rneui/base";
import { Link } from "expo-router";
import QRCodeGenerator from "./QR";

let initialData: Item[] = [{ text: "", key: "" }];
let matchNum = 0;
let teamNum = 0;
let matchTyp = "";

export default function matchScout() {
  const [data, setData] = useState(initialData);

  return (
    <View style={styles.topLevelView}>
      <Text>{matchTyp + " " + teamNum + " " + matchNum}</Text>
      <Link href={"/MatchScouting/QR"} asChild>
        <Pressable
          style={styles.pressable}
          onPress={() => QRCodeGenerator({ text: "No data loaded." })}
        >
          <View style={styles.createView}>
            <Text style={styles.createText}>Create</Text>
          </View>
        </Pressable>
      </Link>
      <DraggableFlatList
        data={(data)}
        keyExtractor={(item) => item.key}
        renderItem={componentsView}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  topLevelView: {
    alignItems: "center",
  },
  pressable: {
    paddingTop: 30,
  },
  createView: {
    backgroundColor: "#429ef5",
    width: 200,
    height: 40,
    alignItems: "center",
    justifyContent: "center",
    borderRadius: 30
  },
  createText: {
    color: '#FFF',
    fontWeight: 'bold'
  }
})

export function setParams(matchNumber: number, teamNumber: number, matchType: string) {
  matchNum = matchNumber;
  teamNum = teamNumber;
  matchTyp = matchType;
}

export function setTemplate(item: Item[]) {
  initialData = item;
}