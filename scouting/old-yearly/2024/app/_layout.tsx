import { Drawer } from 'expo-router/drawer';
import { DrawerContentComponentProps } from "@react-navigation/drawer";
import CustomDrawer from "../components/CustomDrawer";
import 'react-native-gesture-handler';
import { StyleSheet } from 'react-native';

export default function Layout() {
  return (
    <Drawer defaultStatus={"closed"} drawerContent={(props: DrawerContentComponentProps) => <CustomDrawer{...props} />}>
      <Drawer.Screen
        name="MatchScouting/Home"
        options={{
          drawerLabel: 'Home',
          title: 'Home',
        }}
      />
      <Drawer.Screen
        name="MatchScouting/TemplateHome"
        options={{
          drawerLabel: 'Templates',
          title: 'Templates',
        }}
      />
      <Drawer.Screen
        name={"MatchScouting/Setup"}
        options={{
          drawerLabel: 'Setup',
          title: 'Setup',
        }}
      />
      <Drawer.Screen
        name={"MatchScouting/Settings"}
        options={{
          drawerLabel: 'Settings',
          title: "Settings",
        }}
      />
      <Drawer.Screen
        name="index"
        options={{
          drawerItemStyle: styles.height0,
          title: "uhhh ur not supposed to be here"
        }}
      />
      <Drawer.Screen
        name="MatchScouting/MatchScout"
        options={{
          drawerItemStyle: styles.height0,
          title: "Match Scout"
        }}
      />
      <Drawer.Screen
        name="MatchScouting/TemplateEditor"
        options={{
          drawerItemStyle: styles.height0,
          title: "Template Editor"
        }}
      />
      <Drawer.Screen
        name="MatchScouting/QR"
        options={{
          drawerItemStyle: styles.height0,
          title: "QR"
        }}
      />
      <Drawer.Screen
        name="PitScouting/Home"
        options={{
          drawerItemStyle: styles.height0,
          title: "Home"
        }}
      />
    </Drawer>
  );
}

const styles = StyleSheet.create({
  height0: {
    height: 0,
  }
})