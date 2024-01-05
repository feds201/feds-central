import {ScrollView, View} from "react-native";
import {getEventDatabase} from "../../database/eventDatabase";
import {Button, Text} from "@rneui/themed";

export default function Match_Home() {
    const arr: any[] = getEventDatabase();

    //MAP FEATURE IS SO LAGGYYYYYYYYYY
    //Have to save its state in database so it dosent keep doing this each time we load the page

    return(
        <View style={{alignItems: "center"}}>
            <Text h3 style={{alignItems: "center"}}>Matches</Text>
            <ScrollView style={{marginBottom: 0}} showsVerticalScrollIndicator={false}>
                <View style={{paddingBottom: 50}}>
                    {arr.map((tang) => {
                        return (
                            <View key={tang.id} style={{alignItems: "center", paddingTop: 10}}>
                                <Button key={tang.id} title={(tang.matchType).toUpperCase() + " " + tang.matchNumber} buttonStyle={{backgroundColor: '#4287f5', borderRadius: 30, width: 200, alignItems: "center"}}/>
                            </View>
                        );
                    })}
                </View>
            </ScrollView>
        </View>
    );
}