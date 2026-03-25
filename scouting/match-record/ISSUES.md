## General
- it seems like you constantly lock the app in landscape mode now???? we should leave it WHATEVER orientation it wants (ie it can rotate) AT ALL TIMES EXCEPT THE VIDEO PLAYER WHERE WE MUST LOCK INTO LANDSCAPE MODE!!!

## Video Player
- HUGE BUG: scrubbing is completely fucking broken
	- putting my finger down should stop playback. like it FUCKING DID THAT AND YOU FUCKING BROKE IT! I DO NOT NEED TO FUCKING MOVE MY FUCKING FINGER TO ENABLE FUCKING SCRUBBING. FINGER DOWN = STOP FUCKING PLAYING AND ENTER SCRUBBING MORE. IDK WTF YOU FUCKING DID BUT YOU FUCKING BROKE SHIT
	- SCRUBBING IS NOW INCONSISTENT AS FUCK! SOMETIMES I PUT MY FINGER DOWN AND SWIPE ALL THE WAY ACROSS THE FUCKING SCREEN AND IT SCRUBS LIKE <0.5s, OTHER TIMES IT FUCKING SCRUBS THE ENTIRE FUCKING VIDEO. I DON'T FUCKING UNDERSTAND WTF YOU ARE FUCKING DOING. FUCKING EXPLAIN YOURSELF/THE CODE YOU FUCKING WROTE! WHY THIS FUCK IS SCRUBBING NOT FUCKING IDNETICAL EVERY FUCKING TIME I PUT MY FUCKING FINGER DOWN ON THE SCREEN, ANYWHERE ON THE SCREEN, AT ANY TIMESTAMP, ON ANY VIDEO?! NONE OF THAT SHIT SHOULD FUCKING MAKE ANY FUCKING DIFFERENCE. MOVING MY FUCKING FINGER PIXEL LEFT X PIXELS SHOULD SCRUB THE SAME FUCKING AMOUNT NO FUCKING MATTER WHAT.  IT SHOULD BE A FUCKING NONLINEAR FUNCTION THAT FUCKING MAPS (PIXELS_MOVED/TOUCH_CONTAINER_WIDTH) TO SECONDS OF DISPLACEMENT WITH NOTHING FUCKING ELSE BUT A MATH FUNCTION AND SOME FUCKING CONSTANTS. I DONT FUCKING UNDERSTAND WHY YOU INSIST ON FUCKING SILENTLY FUCKING CHANGING FUCKING BEHAVIOR
	- i should be able to put my fucking finger ANYWHERE ON SCREEN (except the button bar / edit+rotate buttons on the video) and it will INSTANTLY FUCKING PAUSE THE VIDEOS. THEN I CAN DRAG LEFT/RIGHT TO SCRUB! THIS FUCKING WORKED BEFORE YOUR FUCKING LAST RETARDED CHANGES.  
- HUGE BUG: FUCKING ZOOM IS JUST COMPLETELY FUCKING NONEXISTENT/BROKEN!?
	- HOW IT SEEMS TO FUCKING WORK NOW:
		- ZOOM IS IMPOSSIBLE TO TRIGGER WHILE PLAYING
		- ZOOM IS IMPOSSIBLE TO TRIGGER WHILE PAUSED WITH DRAWING DISABLED
		- ZOOM IS ONLY TRIGERABLE WHEN FUCKING VIDEO IS PAUSED AND DRAWING IS ON
	- ...THIS IS BEYOND FUCKING RETARDED. I GAVE YOU A CLEAR FUCKING SET OF FUCKING REQUIREMENTS
		- PLAYING + 1 FINGER DOWN = SCRUB
		- PLAYING + 2 FINGERS DOWN = ZOOM
		- PAUSED + 1 FINGER DOWN = DRAW
		- PAUSED + 2 FINGERS DOWN = ZOOM
	- LIKE IDK HOW TO MAKE IT MORE FUCKING SIMPLE FOR YOU!
- HUGE BUG: your red/blue containers were design by an idiot:
	- if i zoom, the fucking rotate and edit buttons zoom lololol wtf???? 
	- and before this bug, if i rotated the video, the edit and zoom buttons rotated along w/ it lolololol wtf???? 
	-  like who the fuck thought this was a fucking good idea. like you fucking did some garbage fucking half ass fucking testing
	- WHAT SHOULD HAPPEN
		- BUTTONS SHOULD NEVER FUCKING MOVE! NOT SCALING, NOT ROTATING WHICH CORNER THEY'RE IN! Same goes for the star for our team and the color indicator at the time
		- THE DRAWINGS SHOULD ALWAYS BE LOCKED TO THE VIDEO!!!! THEY SHOULD PAN AND ZOOM WITH IT (it does) BUT ALSO SHOULD FUCKING DRAW ON THE SAME SPOT ON THE FUCKING VIDEO EVEN WHEN I FUCKING ROTATE (IT FUCKING DOESN'T; see next bug)
	- THIS ENTIRE FUCKING DESIGN IS FUCKING RETARDED!!!!!
- HUGE BUG: your fucking "video sync" fucking "algorithm" doesn't fucking for fucking shit. the fucking videos are off by like 3 fucking seconds again.
	- WHAT THE FUCK ARE YOU FUCK DOING HERE YOU FUCKING ASSHOLE?! 
	- YOU ARE SUPPOSED TO TAKE FUCKING IOS VIDEOS AND USE THEIR CREATION TIME
	- THEN FOR FUCKING NON IOS YOU'RE SUPPOSED TO FUCKING ATTEMPT TO FUCKING PARSE THE TITLES WHICH CAN BE IN 3 FORMATS
		- PXL_YYYYMMDD_HHMMSSmmm.mp4
		- YYYYMMDD_HHMMSS.mp4
		- VID_YYYYMMDD_HHMMSS.mp4
	- YOU ARE NOT FUCKING DOING THIS! YOUR FUCKING VIDEOS ARE FUCKING OFF BY A DISGUSTING FUCKING AMOUNT
- LARGE BUG: individual video rotate fucks up drawings. your transforms are fucked up and don't fucking take scaling into account. think about it. it's extremely straightforward: when you rotate, the fucking video scales down. your drawing does not. you must take into account ALL OF THESE INTO ACCOUNT AND YOU DO NOT!!!!:
	- video size
	- video orientation 
	- video zoom
- LARGE BUG: video mode is BROKEN 
	- when I am in RED ONLY or BLUE ONLY, YOU MUST FUCKING PUT THE FUCKING VIDEO SO THE FUCKING WIDEST FUCKING DIMENSION IS IN THE SAME FUCKING AXIS AS THE FUCKING LARGEST SCREEN DIMENSION! LIKE I CAN'T EVEN BELIEVE I NEED TO REPEAT THIS TO YOU! I HAVE TOLD YOU ABOUT THIS MULTIPLE FUCKING TIMES
		- TODAY IF YOU FUCKING GO INTO Q1 AND TAP VIDEO MODE TO GO RED ONLY, 70% OF THE FUCKING SCREEN IS BLACK BARS BECAUSE THE FUCKING VIDEO ISN'T SHOWN PROPERLY
		- AND FUCKING WORSE YET, IF I  TAPE THE FUCKING VIDEO MODE AGAIN TO GO TO BLUE ONLY, IT FUCKING WORKS
		- THIS MEANS YOU FUCKING HAVE SOME FUCKING DISGUSTING HACKY BULLSHIT THAT FUCKING TREATS RED AND BLUE DIFFERENTLY
- MEDIUM BUG: I don't like that we have black bars when viewing videos side by side. currently we "inscribe" the video, ie it's scaled so that it fits inside it's container. But i'd rather we scale it so the extend past the edge so the other dimension goes edge to edge. in our case: tablet is in landscape and we show 2 vertical videos side by side. then we will scale it so the WIDTH of the vertical video takes up the full width of the red or blue side.
- MINOR TWEAK: when i pause with the pause button, automatically enable draw mode (red)
	- IDEA: MAYBE CHANGE DRAW MODE TO JUST BE DRAW COLOR, AND IF PAUSED VIA BUTTON (NOT SCRUB), DRAW IS INFERED TO BE ENABLED?  TIP: HAVE A HELPER VAR/FUNC THAT'S JUST BASICALLY LIKE CANDRAW = !PLAYING
- MINOR TWEAK: HIGHLIGHT THE PLAY/PAUSE BUTTON SO IT'S EASIER TO SEE.  LIKE JUST A SUBTLE LIGHTER GRAY BG JUST FOR IT

## Sync Bugs
- [ ] HUGE CLARIFICATION: when I import from camera storage or quick share storage, do you copy the videos into our app storage or just ref those other sources?
- [ ] LARGE BUG: sync ui is totally fucking broken! I open the app and tap sync. on import tab it shows "io flash drive" --- idk wtf that fucking means. there is no fucking ios flash drive? i tap the back button, it fucking doesn't fucking nothing
- [ ] MEDIUM BUG: the storage tap is hideous:
	- [ ] we have camera/quick share collapsed at the bottom? like wtf even is this fucking ui? 
		- [ ] WHAT I WANT:
			- [ ] just add 2 more tabs to the fucking view: 5 tabs: import / hist / app storage / camera storage / quick share storage
			- [ ] NOTE: the app storage / camera storage / quick share storage ARE THE SAME UI!!!!
	- [ ] your camera/quick share sections when expanded don't fucking scroll?!?!?!?! i get fucking render issues where they go off the fucking screen and overlap other fucking shit!?!?! did you even fucking test this?!?!?!
	- [ ] there are no fucking thumbnails or way to fucking play the fucking videos?! how the fuck do i fucking know what i'm fucking deleting?! did you fucking think through this at fucking all!? i fucking asked specifically for fucking playback here!!!! 
		- [ ] WHAT I WANT: 
			- [ ] add small thumbnails (height of row = height of thumb) 
			- [ ] AND when i press down on the thumb only, add a view that is like 3x the size of the thumb, is 'absolute' placement such that the bottom right of the view is where my finger is. in this view play the video i'm holding. STOP THE VIDEO/REMOVE THE VIEW as soon as i lift my finger off or move it off the thumb
			- [ ] if i press down on a row and slide my finger down, select every row i swipe thru
	- [ ] when anything is selected the fucking button at the bottom goes fucking into the safe area. fucking do what you did on the import tab (life it up, DONT MAKE IT FULL WIDTH, make it 50% taller -- FIRST fix the import button then duplicate that here!!!)
- [ ] TWEAK: the import videos button is full width?? why? it's hideous, make it 50% taller and be min width to hold content with some gracious horiz padding
- [ ] TWEAK: on import, tapping the side toggle to FULL shows all teams, i'd like to have 2x the visual space between red and blue teams to just be a bit more clear

## Main screen bugs
- [ ] BIG CLARIFICATION: if we're at a district championship:
	- [ ] what am i supposed to be doing differently
	- [ ] will alliances from multiple fields be shown?
- [ ] TWEAK: if i double tap the search bar, i get the keyboard (GOOD), if i dismiss the keyboard, then tap the search button again, they keyboard isn't shown again (IT SHOULD BE).  NOTE: the search bar is focused / has the text indicator even after i hide the keyboard
- [ ] TWEAK: make horiz padding a bit bigger on the top row icons (WHY: so they're easier to click)

## Settings bugs
- [ ] for TBA api key, it says "using default from .env" -- idk why the FUCK you thought it was acceptable to write that retarded internal bullshit?! like FUCKING SHOW THE FUCKING KEY! JUST FUCKING SET THE FUCKING DEFAULT SETTING VALUE TO THE FUCKING .env VALUE! YOU FUCKING MADE THIS FUCKING COMPLEX AND FUCKING TRIED TO BIG "BIG BRAIN" WHEN I FUCKING EXPLCITILY SAID TO BE FUCKING SIMPLE

