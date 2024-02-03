import { TouchableOpacity, TextInput, StyleSheet, Text, View } from "react-native";
import StopwatchTimer, { StopwatchTimerMethods } from "react-native-animated-stopwatch-timer";
import { ScaleDecorator } from "react-native-draggable-flatlist";
import { Item } from "../../types/Item";
import { Button } from "@rneui/base";
import { useRef } from "react";

interface StopwatchProps {
  item: Item;
  saveItem: (item: Item) => Promise<void>;
}

const Stopwatch = ({ item, saveItem }: StopwatchProps) => {
  const stopwatchTimerRef = useRef<StopwatchTimerMethods>(null);

  const handlePause = async () => {
    stopwatchTimerRef.current?.pause();

    const newData = JSON.parse(item.data);
    newData.time = stopwatchTimerRef.current?.getSnapshot();

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
      <StopwatchTimer ref={stopwatchTimerRef} />
      <Button title={"Start"} buttonStyle={styles.button} containerStyle={styles.firstButtonContainer} onPress={() => stopwatchTimerRef.current?.play()} />
      <Button title={"Pause"} buttonStyle={styles.button} containerStyle={styles.restButtonContainer} onPress={() => stopwatchTimerRef.current?.pause()} />
      <Button title={"Reset"} buttonStyle={styles.button} containerStyle={styles.restButtonContainer} onPress={() => stopwatchTimerRef.current?.reset()} />
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
  textInput: {
    marginLeft: 5,
    width: 100,
    textAlign: "center",
  },
  button: {
    borderRadius: 30,
  },
  firstButtonContainer: {
    marginLeft: 10,
  },
  restButtonContainer: {
    marginLeft: 0
  }
})

export default Stopwatch;
