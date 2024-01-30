import { Pressable, ScrollView, View, StyleSheet } from "react-native";
import { getEventDatabase } from "../../database/eventDatabase";
import { Button, Text } from "@rneui/themed";
import { Link } from "expo-router";
import React from "react";
import { setParams } from "./MatchScout";

export default function Match_Home() {
  const arr: any[] = getEventDatabase();

  //MAP FEATURE IS SO LAGGYYYYYYYYYY
  //Have to save its state in database so it dosent keep doing this each time we load the page

  return (
    <View style={styles.topLevelView}>
      <Text h3 style={styles.matchHeadingText}>Matches</Text>
      <ScrollView style={styles.topLevelScrollView} showsVerticalScrollIndicator={false}>
        <View style={styles.scrollViewArea}>
          {arr.map((match) => {
            return (
              <View key={match.id} style={styles.topLevelMatchView}>
                <Link href={"/MatchScouting/MatchScout"} asChild>
                  <Pressable
                    style={styles.pressable}
                    onPress={() => setParams(match.matchNumber, match.teamNumber, match.matchType)}
                  >
                    <View style={styles.matchView}>
                      <Text style={styles.matchViewText}>
                        {(match.matchType).toUpperCase() + " " + match.matchNumber}
                      </Text>
                    </View>
                  </Pressable>
                </Link>
              </View>
            );
          })}
        </View>
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  topLevelView: {
    alignItems: "center",
  },
  matchHeadingText: {
    alignItems: "center",
  },
  topLevelScrollView: {
    marginBottom: 0,
  },
  scrollViewArea: {
    paddingBottom: 50,
  },
  topLevelMatchView: {
    alignItems: "center",
    paddingTop: 10
  },
  pressable: {
    paddingTop: 3,
  },
  matchView: {
    backgroundColor: "#429ef5",
    width: 200,
    height: 40,
    alignItems: "center",
    justifyContent: "center",
    borderRadius: 30
  },
  matchViewText: {
    color: '#FFF',
    fontWeight: 'bold'
  }
})