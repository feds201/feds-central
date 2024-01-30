import React from 'react';
import { View, StyleSheet } from 'react-native';
import QRCode from 'react-native-qrcode-svg';

interface QRCodeGeneratorProps {
  text: string,
}

export default function QRCodeGenerator(props: QRCodeGeneratorProps) {
  return (
    <View style={styles.container}>
      <View style={styles.qrCode}>
        <QRCode
          value={props.text}
          size={200}
          color="black"
          backgroundColor="white"
        />
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#eee',
  },
  wrapper: {
    maxWidth: 300,
    backgroundColor: '#fff',
    borderRadius: 7,
    padding: 20,
    shadowColor: 'rgba(0, 0, 0, 0.1)',
    shadowOffset: { width: 0, height: 10 },
    shadowOpacity: 1,
    shadowRadius: 30,
  },
  title: {
    fontSize: 21,
    fontWeight: '500',
    marginBottom: 10,
  },
  description: {
    color: '#575757',
    fontSize: 16,
    marginBottom: 20,
  },
  input: {
    fontSize: 18,
    padding: 17,
    borderWidth: 1,
    borderColor: '#999',
    borderRadius: 5,
    marginBottom: 20,
  },
  button: {
    backgroundColor: '#3498DB',
    borderRadius: 5,
    padding: 15,
    alignItems: 'center',
  },
  buttonText: {
    color: '#fff',
    fontSize: 18,
  },
  qrCode: {
    marginTop: 20,
    alignItems: 'center',
  },
});