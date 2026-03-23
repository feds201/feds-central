bugs and things to improve as found by me (the user):
## Main screens
- i like how we we highlight our matches, we should highlight ourselves under teams and alliances tabs the same way. i do also like filling in the team/alliance circle, but we don't need the star and i like the indicator on the left and the shading/bg color

## Player
- video orientation is WRONG! see Q1. red video is correct orientation, blue is wrong. the videos SHOULD ALWAYS BE SET UP SO THE WIDER DIRECTION IS VERTICAL!!! YOU MUST IGNORE ORIENTATION THE VIDEO CLAIMS TO BE!!!
- video edit / rotate buttons are tiny, make htem just a BIT bigger, and add more padding for bigger touch targets. but also even when i try to be super precise and click them, i can't, i think the buttons are totally busted
- scrubbing experience really really sucks. on Q1 the red video basically updates what it shows me like once ever 1-2s? that SUCKS for scrubbing. blue video seems better but still sucks. it seems like you completely ignored the prototype learnings for video. send a subagent to explore ~/Downloads/MATCH_RECORD_PROTOTYPES/video to see how it worked? scrubbing MUST BE SMOOTH ON BOTH VIDEOS!!! SMOOTH! IT CAN'T STUTTER OR LAG! WHY: if we want to see a small manuever we want to be able to just scrub back and forth to see it over and over as slow as we want. you show like 1/50 frames which is terrible!
- video mode functionality is totally busted:
	- the icon for red vs blue are IDENTICAL? should be a red, blue, transparent boarder (see audio/muting button)
	- you don't rotate the video when in single video mode. when in single video to line up with the screen so it's as big as possible (max(video-width, video-height) IS IN THE SAME AXIS as max(screen-width, screen-height))
	- in single video mode, we should disable swap button, doesn't make sense
- resetart button should auto play if video was playing before. ie if playing and i press it, scrub to 0:00. if paused and pressed, scrub to beginning and don't play. i assume if you just use scrub func, you don't need to do anything else? idk
- drawing undo/redo/clear should be shown if drawing mode enabled OR there is stuff drawn on screen (ie if i draw then resume, we dim the lines which is good, but controls to clear undo redo are gone)

