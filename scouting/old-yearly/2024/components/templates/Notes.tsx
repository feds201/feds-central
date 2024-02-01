import { TouchableOpacity, TextInput, StyleSheet } from "react-native";
import { ScaleDecorator } from "react-native-draggable-flatlist";
import { Item } from "../../app/MatchScouting/TemplateEditor";

interface NotesProps {
  item: Item
  drag: () => void;
  isActive: boolean;
}

const Notes = ({ item, drag, isActive }: NotesProps, props) => {
  return (
    <ScaleDecorator>
      <TouchableOpacity activeOpacity={1} {...props} disabled={isActive} style={styles.touchableOpacity}>
        <TextInput placeholder={"Title"} textAlign={"center"} style={styles.titleTextInput} />
        <TextInput placeholder={"Notes"} style={styles.notesTextInput} />
      </TouchableOpacity>
    </ScaleDecorator>
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
  },
  notesTextInput: {
    marginTop: 10
  }
});

export default Notes;