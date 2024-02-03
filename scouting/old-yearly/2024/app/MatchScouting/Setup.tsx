import { Input, Text } from '@rneui/themed';
import { StyleSheet, View } from "react-native";
import { Button } from "@rneui/base";
import { useState } from "react";
import { MatchEntity } from '../../database/entity/Match.entity';
import { dataSource } from '../../database/data-source';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { TemplateEntity } from '../../database/entity/Template.entity';

export default function Setup() {

  const [eventCode, setEventCode] = useState('');
  const [robotCode, setRobotCode] = useState('');

  const requestURL = "https://www.thebluealliance.com/api/v3/event/" + eventCode + "/matches/simple";

  return (
    <View style={styles.topLevelView}>
      <Text h3>Event Code</Text>
      <Input
        placeholder='Example: 2022miroc'
        onChangeText={text => setEventCode(text)}
        containerStyle={styles.input}
      />
      <Text h3>Robot Code</Text>
      <Input
        placeholder='Example: R1'
        onChangeText={text => setRobotCode(text)}
        containerStyle={styles.input}
      />

      <Button title={"Submit"} onPress={async () => {
        dataSource.getRepository(MatchEntity).clear();
        await getEventDetailsFromBlueAlliance(requestURL, robotCode.at(0), robotCode.at(1));
        await AsyncStorage.setItem("Event Code", eventCode + " " + robotCode);
      }} />

      <Text h3 style={styles.debugText}>Debug Options</Text>
      {/* <Button title={"Create Database"} onPress={() => createEventDatabase()} containerStyle={styles.firstButton} />
      <Button title={"Add to Database"} onPress={() => addToEventDatabase(1, 201, "qm")} containerStyle={styles.restButtons} />
      <Button title={"Get from Database"} onPress={() => debugPrint()} containerStyle={styles.restButtons} />
      <Button title={"Delete Debug Data"} onPress={() => deleteData()} containerStyle={styles.restButtons} /> */}
    </View>
  );
}

const styles = StyleSheet.create({
  topLevelView: {
    alignItems: "center",
    paddingTop: 20,
  },
  input: {
    width: 200, paddingTop: 20,
  },
  debugText: {
    paddingTop: 30,
  },
  firstButton: {
    paddingTop: 20,
  },
  restButtons: {
    paddingTop: 30,
  }
});

const getEventDetailsFromBlueAlliance = async (requestURL: string, teamColor: string, orderNumber: string) => {
  const TemplateRepository = dataSource.getRepository(TemplateEntity);

  const currentTemplateString = await AsyncStorage.getItem("template");

  const currentTemplate = await TemplateRepository 
                            .createQueryBuilder("template")
                            .where("template.name = :name", {name: currentTemplateString})
                            .getOne();

  const MatchRepository = dataSource.getRepository(MatchEntity);

  try {
    const req = await fetch(requestURL, {
      method: 'GET',
      headers: {
        Accept: 'application/json',
        //Prob a good idea to hide this soon
        'X-TBA-Auth-Key': "SEKJIktW6qP1oovjihNBI4MRclNvbU4mMlyccCqnTlCqO39AqpxUNAvaqlaSuj9F"
      },
    });

    const json: JSON = await req.json();

    // console.log(JSON.stringify(json, null, 2));

    for (const [_, match] of Object.entries(json)) {
      const newMatch = new MatchEntity();

      newMatch.allianceColor = teamColor.toLowerCase() == "r" ? "Red" : "Blue";
      newMatch.allianceRobotNumber = Number(orderNumber);
      newMatch.matchNumber = match["match_number"];
      newMatch.matchType = match["comp_level"];
      newMatch.teamNumber = match.alliances[newMatch.allianceColor.toLowerCase()]["team_keys"][Number(orderNumber) - 1];
      newMatch.data = currentTemplate.data;

      // console.log(newMatch);

      MatchRepository.save(newMatch);
    }

  } catch (error) {
    console.error(error);
  }
};
