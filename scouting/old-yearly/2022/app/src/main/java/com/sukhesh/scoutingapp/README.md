# How to Navigate a Dashboard.xml file
## Overview
To make the most out of the data from scouting robots, we have created a couple of standardized [fields](#fields)

To interact with these fields in the code, we will be using the contentDescription of each GUI element. The format for the contentDescription is also standardized. If you do not follow the standard, we will not accept your changes. Please refer to the [How to format Content Description](#how-to-format-a-content-description) section.

To interact with each type in the code, we will be making use of ***CONTENT DESCRIPTION*** because IDs in Android Studio are a PAIN IN THE *ahem* bad words here :)


## How to format a CONTENT DESCRIPTION
Each field has their specific formats where they are. However, here is a general format.

`Field Name Component`

> NOTE: Name MUST be the same for all of one field

For example, a FiniteInt field for autonHighMakes would look like:

    FiniteInt autonHighMakes plus  
    FiniteInt autonHighMakes minus  
    FiniteInt autonHighMakes tally  


## Fields
1. [FiniteInt](#finiteint)
2. [ClosedQuestion](#closedquestion)
3. [Timer](#timer)

### Overview
Each **field** will have a number of **components**. The field MUST have the correct components with the correct name and object type.

Each field has a corresponding class.

We will NOT accept your changes if your design does not follow these criteria.

### FiniteInt
`FiniteInt Name plus/minus/tally`
#### Field Name
FiniteInt
#### Components
- Plus
    - NAME: plus
    - TYPE: Button
- Minus
    - NAME: minus
    - TYPE: Button
- Tally
    - NAME: tally
    - TYPE: TextView

### SeekBar
`SeekBar Name slider/text`
#### Field Name
SeekBar
##### Components
- Slider
  - NAME: slider
  - TYPE: SeekBar
- Text
  - NAME: text
  - TYPE: TextView

### ClosedQuestion
`ClosedQuestion Name check`
#### Field Name
ClosedQuestion
#### Components
- Check
    - NAME: check
    - TYPE: CheckBox

### Timer
`Timer Name time/start/stop/reset`
#### Field Name
Timer
#### Components
- Time
  - Name: time
  - Type: Chronometer
- Start
  - Name: start
  - Type: Button
- Stop
  - Name: stop
  - Type: Button
- Reset
  - Name: reset
  - Type: Button
