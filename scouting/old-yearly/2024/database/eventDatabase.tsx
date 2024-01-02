import * as SQLite from "expo-sqlite";
import {useState} from "react";

//Initialize Databases
const eventDatabase = SQLite.openDatabase("event.db");

//TABLE FORMAT
//        --------------------- eventInfo ------------------------
//        id(#)---matchNumber(#)---teamNumber(#)---matchType(TEXT)
//        --------------------------------------------------------

export default function createEventDatabase() {
    eventDatabase.transaction(tx => {
        tx.executeSql(
            'CREATE TABLE IF NOT EXISTS eventInfo (id INTEGER PRIMARY KEY AUTOINCREMENT, matchNumber INTEGER, teamNumber INTEGER, matchType TEXT)'
        );
    });
    console.log("Created Database");
}

export function addToEventDatabase(matchNumber: number, teamNumber: number, matchType: string) {
    eventDatabase.transaction(tx => {
        tx.executeSql(
            'INSERT INTO eventInfo (matchNumber, teamNumber, matchType) VALUES (?, ?, ?)',
            [matchNumber, teamNumber, matchType],
        );
    })
    console.log("Added to Database")
}

export function debugPrint() {
    eventDatabase.transaction(tx => {
        tx.executeSql(
            'SELECT * from eventInfo',
            undefined,
            (txObj, resultSet) => console.log(resultSet.rows._array)
        );
    })
}

export function deleteData() {
    eventDatabase.transaction(tx => {
        tx.executeSql(
            'DROP TABLE IF EXISTS eventInfo',
            undefined,
        );
    })
    console.log("Deleted Data");
}

export function getEventDatabase() {
    const[size, setSize] = useState<any[]>([]);
    eventDatabase.transaction(tx => {
        tx.executeSql(
            'SELECT * from eventInfo',
            undefined,
            (txObj, resultSet) => setSize(resultSet.rows._array)
        );
    })

    return size;
}
