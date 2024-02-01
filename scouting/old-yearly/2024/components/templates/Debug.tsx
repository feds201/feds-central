import { TouchableOpacity, StyleSheet } from "react-native";
import { ScaleDecorator } from "react-native-draggable-flatlist";
import { Item } from "../../app/MatchScouting/TemplateEditor";
import { Text } from "@rneui/base";

interface DebugProps {
  item: Item
  drag: () => void;
  isActive: boolean;
}

const Debug = ({ item, drag, isActive }: DebugProps, props) => {
  return (
    <ScaleDecorator>
      <TouchableOpacity
        activeOpacity={1}
        {...props}
        disabled={isActive}
        style={styles.touchableOpacity}>
        <Text style={styles.text}>{item.key}</Text>
      </TouchableOpacity>
    </ScaleDecorator>
  );
}

const styles = StyleSheet.create({
  text: {
    color: "white",
    fontSize: 24,
    fontWeight: "bold",
    textAlign: "center",
    justifyContent: "center"
  },
  touchableOpacity: {
    backgroundColor: "#000",
    height: 0,
    justifyContent: "center"
  }
});

export default Debug;