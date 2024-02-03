import { FlatList, Pressable, StyleSheet, Text, View } from "react-native";
import React, { useEffect, useState } from "react";
import { Link, useLocalSearchParams } from "expo-router";
import { MatchEntity } from "../../../database/entity/Match.entity";
import { dataSource } from "../../../database/data-source";
import { useIsFocused } from "@react-navigation/native";
import { Item } from "../../../types/Item";

import Header from "../../../components/header/Header";
import Stopwatch from "../../../components/stopwatch/Stopwatch";
import Checkbox from "../../../components/checkbox/Checkbox";
import PlusMinus from "../../../components/plusminus/PlusMinus";
import Notes from "../../../components/notes/Notes";
import Slider from "../../../components/slider/Slider";
import Debug from "../../../components/Debug";
import AsyncStorage from "@react-native-async-storage/async-storage";

export default function MatchScout() {
  const { id } = useLocalSearchParams();

  const [match, setMatch] = useState<MatchEntity>(null);
  const [data, setData] = useState<Item[]>([]);

  const isFocused = useIsFocused();

  useEffect(() => {
    if (!isFocused) return;
    const getMatch = async () => {
      // console.log(id);
      const MatchRepository = dataSource.getRepository(MatchEntity);
      const wantedMatch = await MatchRepository
        .createQueryBuilder("match")
        .where("match.id = :id", { id: id })
        .getOne();
      setMatch(wantedMatch);

      setData(JSON.parse(match.data))
      // console.log(data);
    }
    getMatch();
  }, [id, isFocused]);

  const saveItem = async (changedItem: Item): Promise<void> => {
    const newData = data;

    newData.forEach((item) => {
      item = changedItem.key == item.key ? changedItem : item
    })

    setData(newData);

    const newMatch = match;
    newMatch.data = JSON.stringify(newData);
    setMatch(newMatch);

    const MatchRepository = dataSource.getRepository(MatchEntity);
    await MatchRepository.update(match.id, { data: match.data });
  }

  const handleOnPressed = async () => {
    console.log("data: ", data);
    let returnedObject = {
      "matchType": match.matchType,
      "matchNumber": match.matchNumber,
      "teamNumber": match.teamNumber,
      "allianceColor": match.allianceColor,
      "allianceRobotNumber": match.allianceRobotNumber
    };

    data.forEach(obj => {
      const json = JSON.parse(obj.data);
      json["type"] = obj.type;
      console.log(JSON.stringify(json, null, 2));
      returnedObject[obj.name] = json;
    })

    console.log(JSON.stringify(returnedObject, null, 2))
    AsyncStorage.setItem("QR Code Text", JSON.stringify(returnedObject));
  }


  return (
    <>
      {match ? (
        <View style={styles.topLevelView}>
          {/* <View> */}
          <Text>{match.matchType + " " + match.teamNumber + " " + match.matchNumber}</Text>
          <Link href={"/MatchScouting/QRCodeGenerator"} asChild>
            <Pressable
              style={styles.pressable}
              onPress={handleOnPressed}
            >
              <View style={styles.createView}>
                <Text style={styles.createText}>Create</Text>
              </View>
            </Pressable>
          </Link>
          <View>
            <FlatList
              data={(data)}
              keyExtractor={(item) => item.key}
              style={styles.flatList}
              extraData={match.id}
              renderItem={({ item }) => {
                switch (item.type) {
                  case "header":
                    return <Header item={item} saveItem={saveItem} />;
                  case "plusminus":
                    return <PlusMinus item={item} saveItem={saveItem} />
                  case "checkbox":
                    return <Checkbox item={item} saveItem={saveItem} />;
                  case "stopwatch":
                    return <Stopwatch item={item} saveItem={saveItem} />;
                  case "notes":
                    return <Notes item={item} saveItem={saveItem} />;
                  case "slider":
                    return <Slider item={item} saveItem={saveItem} />;
                  default:
                    return <Debug item={item} drag={null} isActive={false} />;
                }
              }}
            />
          </View>
        </View>
      ) : (
        <>
          <Text>Loading Match...</Text>
        </>
      )}
    </>
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
  },
  flatList: {
    marginTop: 10,
  }
});