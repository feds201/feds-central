Your goal is to create a script that generates an .obj file representing the field for this year's game. We will load that into our physics simulator, along with models for the robot and game pieces we already have, so we can simulate matches.

The primary objective is to make sure the field is accurate enough for our physics simulator. The secondary objective is to minimize the obj file complexity so the physics simulator runs fast.

It is NOT an objective to make the field .obj look nice because it will NEVER be looked at visually, it is only internal state for the simulator.

Start by looking thoroughly at the info below from the 2026 game manual. Then make a script to generate the obj file and run it. Place the file at robot/2026-rebuilt/src/main/resources/field_collision.obj (and the script alongside it). Do not delete the script, we may iterate on it.

you MUST include all major field elements:
- 4 bumps
- 4 trenches
- 2 depots
- 2 towers
- 2 hoppers
- the outline/walls of the field

DO NOT INCLUDE (these are irrelevant to our goal and just add more objects for physics sim to track): 
- small details like screws or textures
- driver/human station
- outposts for balls
- small details (like railings for the field edges; just flat vertical walls)
- the scoring table
- signs/text
- april tags
- game pieces 
- visual markings (eg gafers tape lines)

Important notes:
- scoring elements need to have the right geometry so we can actually score
- ramps/bumps need to have the correct geometry so the robot can drive on it
- this should be the "welded" field (if that makes a difference)
- the file's coordinate system should be in meters. The origin (0,0,0) should be located at the corner of the field (if we are looking from the sky down onto the field and the blue alliance is on top / red alliance on the bottom, then the origin is the the top left corner of the field itself. increasing y moves you across the field (the narrower direction). increasing x moves you down the field (towards the red alliance side). increasing z moves you up into the air (ie negative z = underground). 

Below is a direct copy of all the info you will need from the game manual (note: some info may be extra / should be ignored! this is a superset of the
info you will need!):
## FIELD

Each FIELD for REBUILT is an approximately 317.7in (\~8.07m) by 651.2in
(\~16.54m) carpeted area bounded by inward facing surfaces of the
ALLIANCE WALLS, OUTPOSTS, TOWER WALLS, and guardrails.

FIELD boundary in pink

> ![Overhead view of field showing FIELD
> boundary](./game-manual/media/media/image18.png){width="6.645844269466317in"
> height="3.6416666666666666in"}

The FIELD is populated with and surrounded by the following elements:

- 1 OUTPOST per ALLIANCE,

- 1 HUB per ALLIANCE,

- 1 TOWER per ALLIANCE,

- 2 DEPOTS,

- 4 BUMPS, and

- 4 TRENCHES.

The surface of the FIELD is low pile carpet, Shaw Floors, Philadelphia
Commercial, Neyland II 20, "66561 Medallion." Neyland II carpet is not
available for purchase at this time, and the closest equivalent is
[[Shaw, Philadelphia Brand, Profusion 20, Style
54933]{.underline}](https://philadelphiacommercial.com/products/carpet/details/profusion-20/54933/plethora/00520);
see results from evaluation in [[this blog
post]{.underline}](https://community.firstinspires.org/2023-carpet-at-2024-events).

Carpet edges and seams are secured with [[3M^TM^ Premium
M]{.underline}[atte Cloth (Gaffers) Tape GT2, GT3 or comparable Gaffer's
Tape]{.underline}](https://www.3m.com/3M/en_US/p/d/b40065992/). Tears,
rips, and damage to the carpet may be repaired with the same styles of
tape and ROBOTS must be prepared to operate on surfaces made of carpet,
tape, or combinations of both materials as repairs are made through the
course of competition.

Guardrails form the long edges of the FIELD. Guardrails are a 20.0in
(50.8cm) tall system of transparent polycarbonate supported on the top
and bottom by aluminum extrusion. There are 4 gates in the guardrail
that allow access to the FIELD for placement and removal of ROBOTS. The
gate passthrough, when open, is 38.0in (96.5cm) wide. Gates are closed
and shielded during the MATCH.

<figure>
<img src="./game-manual/media/media/image19.png"
style="width:5.56101in;height:3.04722in"
alt="Overhead view of FIELD showing gate locations" />
<figcaption><p>Gate locations</p></figcaption>
</figure>

There are 2 versions of guardrails and DRIVER STATIONS used for
competitions. 1 design is the Welded FIELD which is reflected in the
[[2026 Official *FIRST* FIELD Drawings &
Models](https://www.firstinspires.org/resources/library/frc/playing-field).]{.underline}
The other is designed and sold by AndyMark. [Table 5‑1]{.underline} and

[Table 5‑2]{.underline} illustrate which areas have each kind of FIELD.
While the designs are slightly different, the critical dimensions,
performance, and expected user experience between them are the same
unless otherwise noted. Detailed drawings for the AndyMark design are
posted on the [[AndyMark
website]{.underline}](https://www.andymark.com/products/andymark-field-perimeter).
All illustrations in this manual show the traditional Welded FIELD
design.

  -----------------------------------------------------------------------
               District                           Field Type
  ----------------------------------- -----------------------------------
          *FIRST* Chesapeake                       AndyMark

          *FIRST* California                        Welded

          *FIRST* in Michigan                       Welded

           *FIRST* in Texas                        AndyMark

       *FIRST* Indiana Robotics                    AndyMark

            *FIRST* Israel                          Welded

         *FIRST* Mid-Atlantic                       Welded

        *FIRST* North Carolina                     AndyMark

        *FIRST* South Carolina                      Welded

           *FIRST* Wisconsin                       AndyMark

              NE *FIRST*                           AndyMark

                Ontario                             Welded

           Pacific Northwest                        Welded

               Peachtree                            Welded
  -----------------------------------------------------------------------

  : : District Field Types

\

  -----------------------------------------------------------------------
           Regional Location                      Field Type
  ----------------------------------- -----------------------------------
               Australia                            Welded

                Brazil                             AndyMark

                Canada                              Welded

                 China                             AndyMark

                Mexico                             AndyMark

                Türkiye                            AndyMark

             United States                          Welded
  -----------------------------------------------------------------------

  : Regional Field Types

## Areas, Zones, & Markings 

FIELD areas, zones, and markings of consequence are described below.
Unless otherwise specified, the tape used to mark lines and zones
throughout the FIELD is 2.0in (5.1cm) [[3M™ P]{.underline}[remium Matte
Cloth (Gaffers) Tape
(GT2)]{.underline}](http://multimedia.3m.com/mws/media/1217295O/gaffers-tape.pdf),
[[ProGaff^®^ Premium Professional Grade Gaffer
Tape]{.underline}](https://www.protapes.com/products/pro-gaff-tape-premium-professional-grade-gaffer-tape),
or comparable gaffers tape.

<figure>
<img src="./game-manual/media/media/image20.png"
style="width:5.38333in;height:3.43987in"
alt="Overhead view of field showing Areas, Zones, and lines. " />
<figcaption><p>Areas, markings, and zones</p></figcaption>
</figure>

- **ALLIANCE AREA**: an approximately 360in wide by 134in deep (\~9.14m
  by 3.4m) infinitely tall volume formed by, and including the ALLIANCE
  WALL, OUTPOST, TOWER WALL, the edge of the carpet, and ALLIANCE
  colored tape perpendicular to the DRIVER STATIONS.

- **ALLIANCE ZONE**: A 158.6in deep by 317.7in long (\~4.03m by 8.07m),
  infinitely tall volume formed by an ALLIANCE WALL, TOWER WALL, and
  guardrails. It surrounds an ALLIANCE TOWER and a DEPOT. It is bounded
  by and includes the ROBOT STARTING LINE.

- **CENTER LINE**: a white line that spans the width of the FIELD that
  bisects the NEUTRAL ZONE in half.

- **NEUTRAL ZONE**: A 283in deep by 317.7in long (7.19m by 8.07m),
  infinitely tall volume formed by the BUMPS, TRENCHES, HUBS, and
  guardrails. It surrounds and includes the CENTER LINE.

- **HUMAN STARTING LINE**: a white line spanning the ALLIANCE AREA up to
  the OUTPOST AREA that is parallel to and located 24.0in (61.0cm) from
  the bottom square tube of the ALLIANCE WALL to the near edge of the
  tape.

- **OUTPOST AREA**: a 71.0in wide by 134in deep (1.8m by 3.4m)
  infinitely tall volume bounded by the OUTPOST, edge of carpet, and
  ALLIANCE and white colored tape.

- **ROBOT STARTING LINE**: an ALLIANCE colored line that spans the width
  of the FIELD at the edge of an ALLIANCE'S BASE in front of two
  BARRIERS and an ALLIANCE HUB.

## HUB

<figure>
<img src="./game-manual/media/media/image21.png"
style="width:3.29167in;height:3.42377in" alt="Image of the HUB" />
<figcaption><p>HUB</p></figcaption>
</figure>

A HUB is one of two 47in by 47in (\~1.19m by 1.19m) rectangular prism
structures with an extended opening at the top surface. Each ALLIANCE
has a dedicated HUB centered between two BUMPS located 158.6in (\~4.03m)
away from their ALLIANCE WALL. Each HUB has a set of exits that randomly
distributes FUEL into the NEUTRAL ZONE. A net structure located in the
back of the HUB prevents FUEL launched from most prohibited areas from
entering the opening.

<figure>
<img src="./game-manual/media/media/image22.png"
style="width:3.56578in;height:3.33333in"
alt="Image showing distance from the wall to the HUB" />
<figcaption><p>: HUB distance to the ALLIANCE WALL</p></figcaption>
</figure>

The top of each HUB has a 41.7in (\~1.06m) hexagonal opening into which
ROBOTS can deliver FUEL. The front edge of the opening is 72in (\~1.83m)
off the carpet.

: HUB Dimensions

![](./game-manual/media/media/image23.jpg){width="6.341097987751531in"
height="3.1864818460192477in"}

HUBS have a series of exits at the base of the HUB facing towards the
NEUTRAL ZONE. FUEL processed through the HUB are distributed into the
NEUTRAL ZONE via one of four exits as shown in [Figure 5‑8]{.underline}.
Examples of FUEL distribution from the HUB can be found on the [[Playing
FIELD
webpage]{.underline}](https://www.firstinspires.org/resources/library/frc/playing-field).

<figure>
<img src="./game-manual/media/media/image24.png"
style="width:4.94031in;height:3.37227in"
alt="Image showing path of HUB exits" />
<figcaption><p>: HUB exits (approximation)</p></figcaption>
</figure>

The top angles of the HUB are lit by DMX light bars that indicate if the
HUB is active. See [Table 5‑3]{.underline} for more details about the
various light states in the HUB.

+----------------+---------------+---------------------+--------------+
| Color          | Pre-MATCH     | MATCH               | Post-Match   |
+:==============:+:=============:+:===================:+:============:+
| ALLIANCE color | N/A           | HUB active          | N/A          |
| at 100%        |               |                     |              |
| brightness     |               |                     |              |
+----------------+               +---------------------+              |
| ALLIANCE color |               | HUB deactivation    |              |
| pulsing        |               | warning. Starts 3   |              |
|                |               | seconds before and  |              |
|                |               | continues until     |              |
|                |               | deactivation.       |              |
+----------------+               +---------------------+--------------+
| Purple         |               | N/A                 | FIELD is     |
|                |               |                     | safe for     |
|                |               |                     | FIELD STAFF. |
+----------------+               |                     +--------------+
| Green          |               |                     | FIELD is     |
|                |               |                     | safe for     |
|                |               |                     | all.         |
+----------------+---------------+---------------------+--------------+
| Off            | MATCH ready   | HUB is not active.  | N/A          |
|                | to start.     |                     |              |
+----------------+---------------+---------------------+--------------+

: : HUB Lighting

## BUMP

<figure>
<img src="./game-manual/media/media/image25.png"
style="width:4.66049in;height:2.64028in" alt="Image showing BUMP" />
<figcaption><p>BUMP</p></figcaption>
</figure>

BUMPS are 73.0in (1.854m) wide, 44.4in (1.128m) deep, and 6.513in
(16.54cm) tall structures on either side of the HUB that ROBOTS drive
over. The top surface of each BUMP is made up of 0.5in (1.27cm) thick,
ALLIANCE colored, Orange Peel textured, HDPE ramps at a 15-degree angle
with one ramp sloping down towards the NEUTRAL ZONE and the other ramp
sloping down towards the ALLIANCE ZONE.

## TRENCH

<figure>
<img src="./game-manual/media/media/image26.png"
style="width:4.98817in;height:2.48648in" alt="Image showing TRENCH" />
<figcaption><p>: TRENCH</p></figcaption>
</figure>

TRENCHES are a 65.65in (1.668m) wide, 47.0in (1.194m) deep, and 40.25in
(1.022m) tall structure that ROBOTS drive underneath. The TRENCH extends
from the guardrail to the BUMP on both sides of the FIELD. The space
underneath each TRENCH arm is 50.34in (1.279m) wide, 22.25in (56.52cm)
tall.

TRENCHES along the guardrail closest to the scoring table contain
additional electronics to reach the HUB. The TRENCHES along the
guardrail furthest from the scoring table have a pivot arm that allows
the horizontal portion of the TRENCH to rotate into a vertical position
for post-MATCH ROBOT retrieval and to let FIELD staff reset the field
between matches. The pivot arm will be locked in the horizontal position
during the MATCH.

## DEPOT

<figure>
<img src="./game-manual/media/media/image27.png"
style="width:5.02035in;height:2.58056in" alt="Image showing DEPOT" />
<figcaption><p>: DEPOT</p></figcaption>
</figure>

A DEPOT is a 42.0in (1.07m) wide, 27.0in (68.6cm) deep structure located
along the ALLIANCE WALL. There is 1 DEPOT per ALLIANCE. DEPOTS are made
up of 3.0in (7.62cm) wide, 1.0in (2.54) tall steel barriers. The DEPOT
is secured to the carpet using hook fastener which increases the height
to approximately 1.125in (2.86cm).

## TOWER

<figure>
<img src="./game-manual/media/media/image28.png"
style="width:3.09375in;height:3.9856in" alt="Image showing TOWER" />
<figcaption><p>: TOWER</p></figcaption>
</figure>

A TOWER is a 49.25in (1.251m) wide, 45.0in (1.143m) deep, and 78.25in
(1.988m) tall structure made up of the TOWER WALL, TOWER BASE, UPRIGHTS,
RUNGS and supporting structures. There is 1 TOWER per ALLIANCE. A TOWER
is integrated into each ALLIANCE WALL between DRIVER STATION 2 and
DRIVER STATION 3.

The TOWER BASE is a 39.0in (99.06cm) wide by 45.18in (1.148m) deep plate
that sits on the floor and extends from the TOWER WALL. The TOWER BASE
is powder-coated steel with hook fastener underneath. The edges of the
TOWER BASE are approximately 0.2in (0.5cm) to 0.3in (0.8cm) tall.

The UPRIGHTS are two 72.1in (1.831m) tall, 1.5in (3.81cm) thick, 3.5in
(8.89cm) deep sheet metal box frames that extend vertically up from the
TOWER BASE. The distance between each UPRIGHT is 32.25in (81.92cm).

The UPRIGHTS hold three horizontal RUNGS made up of 1-1/4in Sch 40
(1.66in (4.216cm) OD) pipe. Each RUNG is centered between the UPRIGHT
and extend 5.875in (14.92cm) from the outer face of the UPRIGHT on
either side. The center of the LOW RUNG is located 27.0in (68.58cm) from
the floor. The center of the MID RUNG is located 45.0in (114.3cm) from
the floor. The center of the HIGH RUNG is 63.0in (1.6m) from the floor.
The RUNGS are 18.0in (45.72cm) apart center to center.

The UPRIGHTS and RUNGS are powder-coated red or blue.

Each TOWER has additional supporting structures extending from the
UPRIGHT to the TOWER WALL between approximately 28.40in (72.14cm) and
43.38in (1.102m) off the floor.

<figure>
<img src="./game-manual/media/media/image29.png"
style="width:4.16522in;height:3.55842in"
alt="Image showing TOWER Dimensions" />
<figcaption><p>: TOWER Dimensions</p></figcaption>
</figure>

