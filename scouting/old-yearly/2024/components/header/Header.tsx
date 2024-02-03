import { TouchableOpacity, StyleSheet, Text, View } from "react-native"
import { ScaleDecorator } from "react-native-draggable-flatlist"
import { Item } from "../../types/Item";

interface HeaderProps {
  item: Item;
  saveItem: (item: Item) => Promise<void>;
}

const Header = ({ item, saveItem }: HeaderProps) => {
  return (
    <TouchableOpacity
      activeOpacity={1}
      style={styles.touchableOpacity}
    >
      <Text>{item.name}</Text>
    </TouchableOpacity>
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