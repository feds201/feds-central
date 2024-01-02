import { Drawer } from 'expo-router/drawer';
import {DrawerContentComponentProps} from "@react-navigation/drawer";
import CustomDrawer from "../components/CustomDrawer";
import 'react-native-gesture-handler';

export default function Layout() {
    return (
        <Drawer drawerContent={(props: DrawerContentComponentProps) => <CustomDrawer{...props}/>}>
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
                    drawerItemStyle: { height: 0 },
                    title: "uhhh ur not supposed to be here"
                }}
            />
            <Drawer.Screen
                name="MatchScouting/MatchScout"
                options={{
                    drawerItemStyle: { height: 0 },
                    title: "Match Scout"
                }}
            />
            <Drawer.Screen
                name="MatchScouting/TemplateEditor"
                options={{
                    drawerItemStyle: { height: 0 },
                    title: "Template Editor"
                }}
            />
        </Drawer>
    );
}