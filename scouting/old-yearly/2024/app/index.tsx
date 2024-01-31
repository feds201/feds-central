import 'reflect-metadata';
import 'react-native-gesture-handler'; //Required for app to work
import { Redirect, useRootNavigationState } from "expo-router";

export default function index() {
  //Get the state of the navigation module
  const rootNavigationState = useRootNavigationState();

  //Only navigate if the module is ready
  if (!rootNavigationState?.key) return null;

  return (
    <Redirect href={"/MatchScouting/Home"} />
  );
}