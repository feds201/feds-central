import { TouchableOpacity, TextInput, StyleSheet } from "react-native"
import { ScaleDecorator } from "react-native-draggable-flatlist"
import { Item } from "../../app/MatchScouting/TemplateEditor";

interface HeaderProps {
  item: Item
  drag: () => void;
  isActive: boolean;
}

const Header = ({ item, drag, isActive }: HeaderProps, props) => {
  return (
    <ScaleDecorator>
      <TouchableOpacity
        activeOpacity={1}
        disabled={isActive}
        style={styles.touchableOpacity}
        {...props}
      >
        <TextInput placeholder={"Header Title"} />
      </TouchableOpacity>
    </ScaleDecorator>
  )
}

const styles = StyleSheet.create({
  touchableOpacity: {
    backgroundColor: "#FFFAFA",
    height: 60,
    justifyContent: "center",
    alignItems: "center"
  },
});

export default Header;