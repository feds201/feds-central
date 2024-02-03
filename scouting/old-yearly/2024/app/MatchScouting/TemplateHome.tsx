import React, { useEffect, useState } from 'react';
import { Modal, StyleSheet, View, TextInput, Pressable, ScrollView, Alert } from 'react-native';
import { Button, Text } from "@rneui/themed";
import { Link } from "expo-router";
import { TemplateEntity } from '../../database/entity/Template.entity';
import { dataSource } from '../../database/data-source';
import { useIsFocused } from '@react-navigation/native';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { MatchEntity } from '../../database/entity/Match.entity';

export default function TemplateHome() {
  const [templates, setTemplates] = useState<TemplateEntity[]>(null);

  const [modalVisible, setModalVisible] = useState(false);
  const [name, setName] = useState("");

  const isFocused = useIsFocused();

  useEffect(() => {
    if (!isFocused) return;
    const getTemplates = async () => {
      const TemplateRepository = dataSource.getRepository(TemplateEntity);
      const returnedTemplates = await TemplateRepository.find();
      setTemplates(returnedTemplates);
      // console.log(returnedTemplates);
    }
    getTemplates();
  }, [isFocused]);

  const handlePressed = async (template: TemplateEntity) => {

    await AsyncStorage.setItem("template", template.name);
    Alert.alert('Template Selected', `The '${template.name}' template is now selected`, [
      {
        text: 'Cancel',
        onPress: () => console.log('Cancel Pressed'),
        style: 'cancel',
      },
      { text: 'OK', onPress: () => console.log('OK Pressed') },
    ])

    const MatchRepository = dataSource.getRepository(MatchEntity);

    const matches: MatchEntity[] = await MatchRepository.find();

    matches.forEach((match) => {
      MatchRepository.update(match.id, { data: template.data });
    });
  }

  return (
    <View>
      <View style={styles.buttonView}>
        <Button
          title={"Create New Template"}
          buttonStyle={{ borderRadius: 30 }}
          containerStyle={{ width: 200 }}
          onPress={() => setModalVisible(true)} />
        <ScrollView style={styles.topLevelScrollView} showsVerticalScrollIndicator={false}>
          <View style={styles.scrollViewArea}>
            {templates ? (
              <>
                <Text style={styles.templateHeadingText}> Select which template to use </Text>
                {templates.map((template) => (
                  <View key={template.id} style={styles.topLevelTemplatesView}>
                    <Pressable
                      style={styles.pressableForTemplates}
                      onPress={() => handlePressed(template)}
                    >
                      <View style={styles.templateView}>
                        <Text style={styles.templateViewText}>
                          {template.name}
                        </Text>
                      </View>
                    </Pressable>
                  </View>
                ))}
              </>
            ) : (
              <Text>No templates made.</Text>
            )}
          </View>
        </ScrollView>
      </View>
      <Modal
        animationType={"fade"}
        transparent={true}
        visible={modalVisible}
      >
        <View style={styles.centeredView}>
          <View style={styles.modalView}>
            <Text style={styles.templateName}>Template Name</Text>
            <TextInput
              placeholder={"Enter Template Name"}
              textAlign={"center"}
              onChangeText={(text) => setName(text)}
              style={styles.templateInput} />
            <Link href={{ pathname: "/MatchScouting/Template/[name].tsx", params: { name: name } }} asChild>
              <Pressable style={styles.pressable} onPress={() => setModalVisible(false)}>
                <View style={styles.pressableView}>
                  <Text style={styles.pressableText}>Create</Text>
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
  buttonView: {
    alignItems: "center",
    paddingTop: 20
  },
  templateName: {
    marginBottom: 15,
  },
  templateInput: {
    paddingTop: 10,
  },
  pressable: {
    paddingTop: 30,
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
  },
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
  },


  topLevelTemplatesView: {
    alignItems: "center",
    paddingTop: 10
  },
  pressableForTemplates: {
    paddingTop: 3,
  },
  templateView: {
    backgroundColor: "#429ef5",
    width: 200,
    height: 40,
    alignItems: "center",
    justifyContent: "center",
    borderRadius: 30
  },
  templateViewText: {
    color: '#FFF',
    fontWeight: 'bold'
  },
  topLevelScrollView: {
    marginBottom: 0,
  },
  scrollViewArea: {
    paddingBottom: 50,
  },
  templateHeadingText: {
    paddingTop: 20,
    paddingBottom: 0,
    fontSize: 20,
  }
});