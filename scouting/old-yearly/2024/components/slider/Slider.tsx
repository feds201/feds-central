import { Button, Dialog, Slider as RNEUISlider } from "@rneui/base";
import { TouchableOpacity, TextInput, View, Text, StyleSheet } from "react-native";
import { ScaleDecorator } from "react-native-draggable-flatlist";
import { Item } from "../../types/Item";
import { useState } from "react";

interface SliderProps {
  item: Item;
  saveItem: (item: Item) => Promise<void>;
}

const Slider = ({ item, saveItem }: SliderProps) => {
  const [value, setValue] = useState<number>(JSON.parse(item.data).value ? JSON.parse(item.data).value : 0);
  const [dialog, setDialog] = useState<boolean>(false);
  const [minValue, setMinValue] = useState<number>(0);
  const [step, setStep] = useState<number>(0);
  const [maxValue, setMaxValue] = useState<number>(0);

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
      <Text style={styles.titleTextInput}> {item.name} </Text>
      <View style={styles.sliderView}>
        <RNEUISlider
          minimumValue={minValue}
          step={step}
          maximumValue={maxValue}
          thumbTintColor={"#4287f5"}
          style={styles.slider}
          value={value}
          onValueChange={(value) => handleValueChange(value)} />
        <Text>Value: {value}</Text>
      </View>
    </TouchableOpacity>
  );
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
  titleTextInput: {
    marginLeft: 5,
    width: 100,
    textAlign: "center"
  },
  sliderView: {
    flex: 1,
    alignItems: 'stretch',
    justifyContent: 'center'
  },
  slider: {
    marginRight: 40
  },
  dialog: {
    backgroundColor: "#fff",
  }
})

export default Slider;