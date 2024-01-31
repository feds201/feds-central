import { DataSource } from "typeorm";
import { Match } from "./entity/Match";
import { typeORMDriver } from 'react-native-quick-sqlite';

export const dataSource = new DataSource({
  database: 'scoutingapp-typeorm.db',
  entities: [Match],
  location: '.',
  logging: [],
  synchronize: true,
  type: 'react-native',
  driver: typeORMDriver,
})