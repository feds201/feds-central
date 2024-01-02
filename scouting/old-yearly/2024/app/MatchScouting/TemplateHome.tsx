import React, {useState} from 'react';
import {Modal, StyleSheet, View, TextInput, Pressable} from 'react-native';
import {Button, Text} from "@rneui/themed";
import {Link} from "expo-router";

export default function TemplateHome() {

    const [modalVisible, setModalVisible] = useState(false);
    const [name, setName] = useState("");

    return (
        <View>
            <View style={{alignItems: "center", paddingTop: 20}}>
                <Button title={"Create New Template"} buttonStyle={{borderRadius: 30}} containerStyle={{width: 200}} onPress={() => setModalVisible(true)}/>
            </View>
            <Modal
                animationType={"fade"}
                transparent={true}
                visible={modalVisible}
                onRequestClose={() => {
                    setModalVisible(!modalVisible);
                }}>
                <View style={styles.centeredView}>
                    <View style={styles.modalView}>
                        <Text style={{marginBottom: 15}}>Template Name</Text>
                        <TextInput placeholder={"Enter Template Name"} textAlign={"center"} onChangeText={(text) => setName(text)} style={{paddingTop: 10}}/>
                        <Link href={"/MatchScouting/TemplateEditor"} asChild>
                            <Pressable style={{paddingTop: 30}} onPress={() => console.log("Pass in params")}>
                                <View style={{backgroundColor: "#429ef5", width: 200, height: 40, alignItems: "center", justifyContent: "center", borderRadius: 30}}>
                                    <Text style={{color: '#FFF', fontWeight: 'bold'}}>Create</Text>
                                </View>
                            </Pressable>
                        </Link>
                    </View>
                </View>
            </Modal>
        </View>
    );

}

const styles = StyleSheet.create({
    centeredView: {
        flex: 1,
        justifyContent: 'center',
        alignItems: 'center',
        marginTop: 54,
        backgroundColor: 'rgba(0,0,0,0.5)'
    },
    modalView: {
        margin: 20,
        backgroundColor: 'white',
        borderRadius: 20,
        padding: 35,
        alignItems: 'center',
        shadowColor: '#000',
        shadowOffset: {
            width: 0,
            height: 2,
        },
        shadowOpacity: 0.25,
        shadowRadius: 4,
        elevation: 5,
    }
});