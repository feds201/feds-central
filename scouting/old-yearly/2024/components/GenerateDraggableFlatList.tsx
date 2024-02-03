import { RenderItemParams } from "react-native-draggable-flatlist";
import { Item } from "../types/Item";
import HeaderTemplate from "./header/HeaderTemplate";
import PlusMinusTemplate from "./plusminus/PlusMinusTemplate";
import CheckboxTemplate from "./checkbox/CheckboxTemplate";
import StopwatchTemplate from "./stopwatch/StopwatchTemplate";
import NotesTemplateTemplate from "./notes/NotesTemplate";
import SliderTemplate from "./slider/SliderTemplate";

import Debug from "./Debug";
import Header from "./header/Header";
import PlusMinus from "./plusminus/PlusMinus";
import Checkbox from "./checkbox/Checkbox";
import Stopwatch from "./stopwatch/Stopwatch";
import Notes from "./notes/Notes";
import Slider from "./slider/Slider";
import { ListRenderItem } from "react-native";

export const templateViewGenerator = ({ item, drag, isActive }: RenderItemParams<Item>) => {
  switch (item.type) {
    case "header":
      return <HeaderTemplate item={item} drag={drag} isActive={isActive} />;
    case "plusminus":
      return <PlusMinusTemplate item={item} drag={drag} isActive={isActive} />
    case "checkbox":
      return <CheckboxTemplate item={item} drag={drag} isActive={isActive} />;
    case "stopwatch":
      return <StopwatchTemplate item={item} drag={drag} isActive={isActive} />;
    case "notes":
      return <NotesTemplateTemplate item={item} drag={drag} isActive={isActive} />;
    case "slider":
      return <SliderTemplate item={item} drag={drag} isActive={isActive} />;
    default:
      return <Debug item={item} drag={drag} isActive={isActive} />;
  }
};

// export const matchViewGenerator = (item: Item, saveItem: (item: Item) => Promise<void>) => {
//   switch (item.type) {
//     case "header":
//       return <Header item={item} saveItem={saveItem} />;
//     case "plusminus":
//       return <PlusMinus item={item} saveItem={saveItem} />
//     case "checkbox":
//       return <Checkbox item={item} saveItem={saveItem} />;
//     case "stopwatch":
//       return <Stopwatch item={item} saveItem={saveItem} />;
//     case "notes":
//       return <Notes item={item} saveItem={saveItem} />;
//     case "slider":
//       return <Slider item={item} saveItem={saveItem} />;
//     default:
//       return <Debug item={item} drag={null} isActive={false} />;
//   }
// }


// export const flatComponentsView = ({ item, drag, isActive }: RenderItemParams<Item>) => {
//   const props = {} // dont delete this
//   switch (item.type) {
//     case "header":
//       return <HeaderTemplate item={item} drag={drag} isActive={isActive} {...props} />;
//     case "plusminus":
//       return <PlusMinusTemplate item={item} drag={drag} isActive={isActive} {...props} />
//     case "checkbox":
//       return <CheckboxTemplate item={item} drag={drag} isActive={isActive} {...props} />;
//     case "stopwatch":
//       return <StopwatchTemplate item={item} drag={drag} isActive={isActive} {...props} />;
//     case "notes":
//       return <NotesTemplateTemplate item={item} drag={drag} isActive={isActive} {...props} />;
//     case "slider":
//       return <SliderTemplate item={item} drag={drag} isActive={isActive} {...props} />;
//     default:
//       return <Debug item={item} drag={drag} isActive={isActive} {...props} />;
//   }
// };