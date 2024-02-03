import { TouchableOpacity, TextInput, Text, View } from "react-native";
import { Button } from "@rneui/base";
import { ScaleDecorator } from "react-native-draggable-flatlist";
import { StyleSheet } from "react-native";
import { Item } from "../../types/Item";
import { useEffect, useState } from "react";

interface PlusMinusProps {
  item: Item;
  saveItem: (item: Item) => Promise<void>;
}

const PlusMinus = ({ item, saveItem }: PlusMinusProps) => {
  const [value, setValue] = useState<number>(JSON.parse(item.data).value ? JSON.parse(item.data).value : 0);

  const handleValueChange = async (newValue: number) => {
    setValue(newValue);

    const newData = JSON.parse(item.data);
    newData.value = newValue;

    const newItem = item;
    newItem.data = JSON.stringify(newData);
    await saveItem(newItem);
  }

  return (
    <TouchableOpacity
      activeOpacity={1}
      style={styles.touchableOpacity}
    >
      <Text style={styles.textInput}>{item.name}</Text>
      <Button title={"+"} buttonStyle={styles.buttonStyle} containerStyle={styles.plusContainerStyle} onPress={() => handleValueChange(value + 1)} />
      <Text id={item.key} style={styles.text}>{value}</Text>
      <Button title={"-"} buttonStyle={styles.buttonStyle} containerStyle={styles.minusContainerStyle} onPress={() => handleValueChange(value - 1)} />
    </TouchableOpacity>
  )
}


const styles = StyleSheet.create({
  touchableOpacity: {
    backgroundColor: "#FFFAFA",
    height: 100,
    alignItems: "flex-start",
    flex: 1,
    flexDirection: "row",
    flexWrap: "wrap",
    alignContent: "center"
  },
  textInput: {
    marginLeft: 5,
    width: 100,
    textAlign: "center"
  },
  buttonStyle: {
    borderRadius: 30,
  },
  plusContainerStyle: {
    width: 60,
    marginLeft: 50,
  },
  minusContainerStyle: {
    width: 60,
    marginLeft: 20,
  },
  text: {
    marginLeft: 20
  }
});

export default PlusMinus;