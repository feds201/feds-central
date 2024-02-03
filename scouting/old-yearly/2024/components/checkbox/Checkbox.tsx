import { CheckBox } from "@rneui/base";
import { TouchableOpacity, TextInput, StyleSheet, Text, View } from "react-native";
import { ScaleDecorator } from "react-native-draggable-flatlist";
import { useState } from "react";
import { Item } from "../../types/Item";

interface CheckboxProps {
  item: Item;
  saveItem: (item: Item) => Promise<void>;
}

const Checkbox = ({ item, saveItem }: CheckboxProps) => {
  const [checked, setChecked] = useState<boolean>(JSON.parse(item.data).checked ? true : false);

  const handlePress = async () => {
    setChecked(!checked);

    const newData = JSON.parse(item.data);
    newData.checked = checked;

    const newItem = item;
    newItem.data = JSON.stringify(newData);
    await saveItem(newItem);
  }


  return (
    <TouchableOpacity
      activeOpacity={1}
      style={styles.touchableOpacity}
    >
      <CheckBox checked={checked} onPress={handlePress} />
      <Text
        style={styles.checkbox}
      > {item.name} </Text>
    </TouchableOpacity>
  )
}

const styles = StyleSheet.create({
  touchableOpacity: {
    backgroundColor: "#FFFAFA",
    alignItems: "flex-start",
    flex: 1,
    flexDirection: "row",
    flexWrap: "wrap",
    alignContent: "center"
  },
  checkbox: {
    marginLeft: 5,
    width: 100
  }
});

export default Checkbox;