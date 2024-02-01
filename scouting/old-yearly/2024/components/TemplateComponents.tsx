import { RenderItemParams } from "react-native-draggable-flatlist";
import { Item } from "../app/MatchScouting/TemplateEditor";
import Header from "./templates/Header";
import PlusMinus from "./templates/PlusMinus";
import Checkbox from "./templates/Checkbox";
import Stopwatch from "./templates/Stopwatch";
import Notes from "./templates/Notes";
import Slider from "./templates/Slider";

export const componentsView = ({ item, drag, isActive }: RenderItemParams<Item>) => {
  const props = {
    onLongPress: drag,
  }
  switch (item.text) {
    case "header":
      return <Header item={item} drag={drag} isActive={isActive} {...props} />;
    case "plusminus":
      return <PlusMinus item={item} drag={drag} isActive={isActive} {...props} />
    case "checkbox":
      return <Checkbox item={item} drag={drag} isActive={isActive} {...props} />;
    case "stopwatch":
      return <Stopwatch item={item} drag={drag} isActive={isActive} {...props} />;
    case "notes":
      return <Notes item={item} drag={drag} isActive={isActive} {...props} />;
    case "slider":
      return <Slider item={item} drag={drag} isActive={isActive} {...props} />;
    default:
      return <Notes item={item} drag={drag} isActive={isActive} {...props} />;
  }
};

export const flatComponentsView = ({ item, drag, isActive }: RenderItemParams<Item>) => {
  const props = {} // dont delete this
  switch (item.text) {
    case "header":
      return <Header item={item} drag={drag} isActive={isActive} {...props} />;
    case "plusminus":
      return <PlusMinus item={item} drag={drag} isActive={isActive} {...props} />
    case "checkbox":
      return <Checkbox item={item} drag={drag} isActive={isActive} {...props} />;
    case "stopwatch":
      return <Stopwatch item={item} drag={drag} isActive={isActive} {...props} />;
    case "notes":
      return <Notes item={item} drag={drag} isActive={isActive} {...props} />;
    case "slider":
      return <Slider item={item} drag={drag} isActive={isActive} {...props} />;
    default:
      return <Notes item={item} drag={drag} isActive={isActive} {...props} />;
  }
};