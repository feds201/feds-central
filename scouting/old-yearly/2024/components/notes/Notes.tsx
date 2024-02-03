import { TouchableOpacity, TextInput, StyleSheet, Text, View } from "react-native";
import { ScaleDecorator } from "react-native-draggable-flatlist";
import { Item } from "../../types/Item";
import { useState } from "react";

interface NotesProps {
  item: Item;
  saveItem: (item: Item) => Promise<void>;
}

const Notes = ({ item, saveItem }: NotesProps) => {
  const [text, setText] = useState<string>(JSON.parse(item.data).notes ? JSON.parse(item.data).notes : "");

  const handleChangeText = async (text: string) => {
    setText(text);

    const newData = JSON.parse(item.data);
    newData.notes = text;

    const newItem = item;
    newItem.data = JSON.stringify(newData);
    await saveItem(newItem);
  }

  return (
    <TouchableOpacity activeOpacity={1} style={styles.touchableOpacity}>
      <Text style={styles.titleTextInput}> {item.name} </Text>
      <TextInput placeholder={"Notes"} style={styles.notesTextInput} value={text} onChangeText={(text) => handleChangeText(text)} />
    </TouchableOpacity>
  );
}

const styles = StyleSheet.create({
  touchableOpacity: {
    backgroundColor: "#FFFAFA",
    height: 100,
    flex: 1,
    alignContent: "center",
    alignItems: "center"
  },
  titleTextInput: {
    width: 100,
    textAlign: "center",
  },
  notesTextInput: {
    marginTop: 10
  }
});

export default Notes;