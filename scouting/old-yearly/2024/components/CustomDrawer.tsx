import {Pressable, View} from "react-native";
import {DrawerContentComponentProps, DrawerItemList} from "@react-navigation/drawer";
import { Text } from '@rneui/themed';
import {Link} from "expo-router";
import React, {useState} from "react";
const CustomDrawer = (props: DrawerContentComponentProps) => {
    const[visible, setVisibility] = useState(false);
    return (
        <View style={{ flex: 1 }}>
            <View style={{alignItems: "center", paddingTop: 30}}>
                <Text h4 style={{}}>Match Scouting</Text>
            </View>
            <View
                style={{
                    borderTopWidth: 1,
                    borderTopColor: "#ccc",
                }}
            >
            </View>
            <View style={{ flex: 1, backgroundColor: "#fff", paddingTop: 0 }}>
                <DrawerItemList {...props} />
            </View>
            <View style={{marginBottom: 20, alignItems: "center"}}>
                <Link href={"/PitScouting/Home"} asChild>
                    <Pressable  style={{paddingTop: 30}} onPress={() => setVisibility(false)}>
                        <View style={{backgroundColor: "#429ef5", width: 200, height: 40, alignItems: "center", justifyContent: "center", borderRadius: 30}}>
                            <Text style={{color: '#FFF', fontWeight: 'bold'}}>Pit Scouting</Text>
                        </View>
                    </Pressable>
                </Link>
            </View>
        </View>
    );
};

export default CustomDrawer;