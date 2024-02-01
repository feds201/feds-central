import { TouchableOpacity, TextInput } from "react-native";
import StopwatchTimer, { StopwatchTimerMethods } from "react-native-animated-stopwatch-timer";
import { ScaleDecorator } from "react-native-draggable-flatlist";
import { Item } from "../../app/MatchScouting/TemplateEditor";
import { Button } from "@rneui/base";
import { useRef } from "react";

interface StopwatchProps {
  item: Item
  drag: () => void;
  isActive: boolean;
}

const Stopwatch = ({ item, drag, isActive }: StopwatchProps, props) => {
  const stopwatchTimerRef = useRef<StopwatchTimerMethods>(null);

  return (
    <ScaleDecorator>
      <TouchableOpacity activeOpacity={1} {...props} disabled={isActive} style={{ backgroundColor: "#FFFAFA", height: 100, alignItems: "flex-start", flex: 1, flexDirection: "row", flexWrap: "wrap", alignContent: "center" }}>
        <TextInput placeholder={"Title"} textAlign={"center"} style={{ marginLeft: 5, width: 100 }} />
        <StopwatchTimer ref={stopwatchTimerRef} />
        <Button title={"Start"} buttonStyle={{ borderRadius: 30 }} containerStyle={{ marginLeft: 10 }} onPress={() => stopwatchTimerRef.current?.play()} />
        <Button title={"Pause"} buttonStyle={{ borderRadius: 30 }} containerStyle={{ marginLeft: 0 }} onPress={() => stopwatchTimerRef.current?.pause()} />
        <Button title={"Reset"} buttonStyle={{ borderRadius: 30 }} containerStyle={{ marginLeft: 0 }} onPress={() => stopwatchTimerRef.current?.reset()} />
      </TouchableOpacity>
    </ScaleDecorator>
  );
}

export default Stopwatch;
