import React, { useMemo, useRef, useState } from "react";
import { View, StyleSheet, TouchableOpacity } from "react-native";
import BottomSheet from "@gorhom/bottom-sheet";
import DraggableFlatList from "react-native-draggable-flatlist/src/components/DraggableFlatList";
import { templateViewGenerator } from "../../../components/GenerateDraggableFlatList";
import MaterialIcons from "react-native-vector-icons/MaterialIcons";
import Entypo from "react-native-vector-icons/Entypo";
import MaterialCommunityIcons from "react-native-vector-icons/MaterialCommunityIcons";
import Ionicons from "react-native-vector-icons/Ionicons"
import Feather from "react-native-vector-icons/Feather"
import { Button } from "@rneui/base";
import { Item } from "../../../types/Item";
import { dataSource } from "../../../database/data-source";
import { TemplateEntity } from "../../../database/entity/Template.entity";
import { useLocalSearchParams } from "expo-router";
import AsyncStorage from "@react-native-async-storage/async-storage";

export default function Template() {
  const { name } = useLocalSearchParams();

  const [data, setData] = useState<Item[]>([]);
  const [uniqueKey, setUniqueKey] = useState<number>(1000);

  const bottomSheetRef = useRef<BottomSheet>(null);

  const snapPoints = useMemo(() => ['3.5%', '38%'], []);

  function pushComponent(type: string) {
    setData([...data, { type: type, key: uniqueKey.toString(), name: "", data: "{}" }]);
    setUniqueKey(uniqueKey + 1);
  }

  const handleFinish = async () => {
    const currentData = data;
    for (let i = 0; i < currentData.length; i++) {
      currentData[i].key = i.toString();
    }

    const TemplateRepository = dataSource.getRepository(TemplateEntity);
    const newTemplate = new TemplateEntity();

    newTemplate.name = name.slice(0, name.length - 4) as string;
    newTemplate.data = JSON.stringify(currentData);

    console.log(newTemplate);

    TemplateRepository.save(newTemplate);

    await AsyncStorage.setItem("template", newTemplate.name);
  }

  return (
    <View>
      <View style={styles.buttonView}>
        <Button
          title={"Finish"}
          buttonStyle={styles.button}
          onPress={handleFinish}
        />
        <DraggableFlatList
          data={(data)}
          onDragEnd={({ data }) => setData(data)}
          keyExtractor={(item) => item.key}
          renderItem={templateViewGenerator}
        />
      </View>
      <BottomSheet
        ref={bottomSheetRef}
        index={1}
        snapPoints={snapPoints} >
        <View style={styles.contentContainer}>
          <TouchableOpacity style={styles.labelOption} onPress={() => pushComponent("header")}>
            <MaterialCommunityIcons name="label" size={35} color="#fff" />
          </TouchableOpacity>
          <TouchableOpacity style={styles.plusMinusOption} onPress={() => pushComponent("plusminus")}>
            <MaterialCommunityIcons name="plus-minus-variant" size={35} color="#fff" />
          </TouchableOpacity>
          <TouchableOpacity style={styles.checkboxOption} onPress={() => pushComponent("checkbox")}>
            <Ionicons name="checkbox-outline" size={35} color="#fff" />
          </TouchableOpacity>
          <TouchableOpacity style={styles.stopwatchOption} onPress={() => pushComponent("stopwatch")}>
            <Entypo name="stopwatch" size={35} color="#fff" />
          </TouchableOpacity>
          <TouchableOpacity style={styles.notesOption} onPress={() => pushComponent("notes")}>
            <MaterialIcons name="notes" size={35} color="#fff" />
          </TouchableOpacity>
          <TouchableOpacity style={styles.slidersOption} onPress={() => pushComponent("slider")}>
            <Feather name="sliders" size={35} color="#fff" />
          </TouchableOpacity>
        </View>
      </BottomSheet>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: "#fff",
  },
  contentContainer: {
    backgroundColor: "#fff",
    flexDirection: "row",
    flexWrap: "wrap"
  },
  footer: {
    height: 400
  },
  buttonView: {
    height: "100%",
  },
  button: {
    height: 50,
  },
  labelOption: {
    backgroundColor: "#4287f5",
    borderRadius: 100,
    padding: 30,
    marginLeft: 20
  },
  plusMinusOption: {
    backgroundColor: "#4287f5",
    borderRadius: 200,
    padding: 30,
    marginLeft: 18
  },
  checkboxOption: {
    backgroundColor: "#4287f5",
    borderRadius: 100,
    padding: 30,
    marginLeft: 18
  },
  stopwatchOption: {
    backgroundColor: "#4287f5",
    borderRadius: 100,
    padding: 30,
    marginLeft: 20,
    marginTop: 20
  },
  notesOption: {
    backgroundColor: "#4287f5",
    borderRadius: 100,
    padding: 30,
    marginLeft: 20,
    marginTop: 20
  },
  slidersOption: {
    backgroundColor: "#4287f5",
    borderRadius: 100,
    padding: 30,
    marginLeft: 20,
    marginTop: 20
  }
});