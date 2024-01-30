import { Pressable, StyleSheet, View } from "react-native";
import { DrawerContentComponentProps, DrawerItemList } from "@react-navigation/drawer";
import { Text } from '@rneui/themed';
import { Link } from "expo-router";
import React, { useState } from "react";
const CustomDrawer = (props: DrawerContentComponentProps) => {
  const [visible, setVisibility] = useState(false);
  return (
    <View style={styles.topLevelView}>
      <View style={styles.headingTextView}>
        <Text h4>Match Scouting</Text>
      </View>
      <View
        style={styles.border}
      >
      </View>
      <View style={styles.drawerItemListView}>
        <DrawerItemList {...props} />
      </View>
      <View style={styles.linkView}>
        <Link href={"/PitScouting/Home"} asChild>
          <Pressable style={styles.pressable} onPress={() => setVisibility(false)}>
            <View style={styles.pressableView}>
              <Text style={styles.pressableText}>Pit Scouting</Text>
            </View>
          </Pressable>
        </Link>
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  topLevelView: {
    flex: 1,
  },
  headingTextView: {
    alignItems: "center",
    paddingTop: 30
  },
  border: {
    borderTopWidth: 1,
    borderTopColor: "#ccc",
  },
  drawerItemListView: {
    flex: 1,
    backgroundColor: "#fff",
    paddingTop: 0
  },
  linkView: {
    marginBottom: 20,
    alignItems: "center"
  },
  pressable: {
    paddingTop: 30
  },
  pressableView: {
    backgroundColor: "#429ef5",
    width: 200,
    height: 40,
    alignItems: "center",
    justifyContent: "center",
    borderRadius: 30
  },
  pressableText: {
    color: '#FFF',
    fontWeight: 'bold'
  }
});

export default CustomDrawer;