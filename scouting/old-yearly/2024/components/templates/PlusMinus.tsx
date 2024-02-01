import { TouchableOpacity, TextInput, Text } from "react-native";
import { Button } from "@rneui/base";
import { ScaleDecorator } from "react-native-draggable-flatlist";
import { StyleSheet } from "react-native";
import { Item } from "../../app/MatchScouting/TemplateEditor";
import { useState } from "react";

interface PlusMinusProps {
  item: Item;
  drag: () => void;
  isActive: boolean;
}

const PlusMinus = ({ item, drag, isActive }: PlusMinusProps, props) => {
  const [value, setValue] = useState<number>(0);
  return (
    <ScaleDecorator>
      <TouchableOpacity
        activeOpacity={1}
        {...props}
        disabled={isActive}
        style={styles.touchableOpacity}>
        <TextInput placeholder={"Title"} textAlign={"center"} style={styles.textInput} />
        <Button title={"+"} buttonStyle={styles.buttonStyle} containerStyle={styles.plusContainerStyle} onPress={() => setValue(value + 1)} />
        <Text id={item.key} style={styles.text}>{value}</Text>
        <Button title={"-"} buttonStyle={styles.buttonStyle} containerStyle={styles.minusContainerStyle} onPress={() => setValue(value - 1)} />
      </TouchableOpacity>
    </ScaleDecorator>
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
    width: 100
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