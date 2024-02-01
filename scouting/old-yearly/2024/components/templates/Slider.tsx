import { Button, Dialog, Slider as RNEUISlider } from "@rneui/base";
import { TouchableOpacity, TextInput, View, Text, StyleSheet } from "react-native";
import { ScaleDecorator } from "react-native-draggable-flatlist";
import { Item } from "../../app/MatchScouting/TemplateEditor";
import { useState } from "react";

interface SliderProps {
  item: Item
  drag: () => void;
  isActive: boolean;
}

const Slider = ({ item, drag, isActive }: SliderProps, props) => {
  const [value, setValue] = useState<number>(0);
  const [dialog, setDialog] = useState<boolean>(false);
  const [minValue, setMinValue] = useState<number>(0);
  const [step, setStep] = useState<number>(0);
  const [maxValue, setMaxValue] = useState<number>(0);

  return (
    <ScaleDecorator>

      <TouchableOpacity
        activeOpacity={1}
        {...props}
        disabled={isActive}
        style={styles.touchableOpacity}>
        <TextInput placeholder={"Title"} textAlign={"center"} style={styles.titleTextInput} />
        <View style={styles.sliderView}>
          <RNEUISlider
            minimumValue={minValue}
            step={step}
            maximumValue={maxValue}
            thumbTintColor={"#4287f5"}
            style={styles.slider}
            value={value}
            onValueChange={(value) => setValue(value)} />
          <Text>Value: {value}</Text>
        </View>
        <Button title={"Options"} onPress={() => setDialog(true)} />
      </TouchableOpacity>

      <Dialog
        overlayStyle={styles.dialog}
        isVisible={dialog}
        onBackdropPress={() => setDialog(!dialog)}>
        <Dialog.Title title="Options" />
        <Dialog.Actions>
          <TextInput placeholder={"MIN VALUE"} onChangeText={(value) => setMinValue(parseInt(value))} />
          <TextInput placeholder={"STEP VALUE"} onChangeText={(value) => setStep(parseInt(value))} />
          <TextInput placeholder={"MAX VALUE"} onChangeText={(value) => setMaxValue(parseInt(value))} />
          <Button title={"Submit"} onPress={() => setDialog(false)} />
        </Dialog.Actions>
      </Dialog>

    </ScaleDecorator>
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
    width: 100
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