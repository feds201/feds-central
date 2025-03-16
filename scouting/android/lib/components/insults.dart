import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';

Widget ShowInsults() {
  return Card(
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
    ),
    elevation: 6,
    child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [Colors.purple.shade300, Colors.deepPurple.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Symbols.taunt, color: Colors.white, size: 24),
              const SizedBox(width: 10),
              Text(
                'Every Second Insult',
                style: GoogleFonts.roboto(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _getRandomInsult(),
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          // Disclaimer with beautiful styling
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.sentiment_satisfied_alt,
                  color: Colors.white.withOpacity(0.9),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  "All in good fun, don't take it seriously!",
                  style: GoogleFonts.roboto(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Colors.white.withOpacity(0.9),
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

String _getRandomInsult() {
  List<String> insults = [
    // memes:
    //Timothy
    "Timothy, oh Timothy,Tripped on a rock and lost his tea!(Now he's just mothy, sipping air instead of coffee.) ",
    "Timothy, the gym is free But he’d rather nap under a tree. (Workout? Nah. Dreaming of snacks instead.)",
    "Timothy, the symphony, Played his trumpet in disharmony. (They said stop, but he played non-stop.) ",
    "Timothy, full of energy, Tripped and spilled his cup of tea. (Now he’s just Tim-oh-pee, sad and tea-free.) ",
    "Timothy, the referee, Accidentally called a foul on a tree (The tree protested, but Tim stood firmly.) ",
// SPREAD SHEETS SPREADSHEETS SPREADSHEETS
// Bring back the buzz
// Shorty king
// Do you need someone to reach the top shelf
// Lock-in...

    //Sukhesh
    "Sukhesh, oh Sukhesh,Thinks he’s cool, but he's just a mess.(Tripped on air, spilled his drink—now he’s drenched, no less! )",
    "Sukhesh tried to flex his cash,Turns out it's all just fake mustache.(Big talk, small wallet—living life on borrowed stash. )",
    "Sukhesh says he’s fast and fresh,But even a turtle makes him stress.(Slow-motion legend, breaking records in reverse. )",
    "Sukhesh thinks he's got that drip,But his style looks like a garage sale flip.(Mismatched socks and a shirt that rips—fashion police, please assist! )",
    "Sukhesh, the king of trash talk,But runs away when it’s time to walk.",

    //Adit
    "Adit, oh Adit, Hit his head on a door—just a bit!(Now he ducks, but still gets stuck.)",
    "Adit, the Aussie lad, Tried to surf but wiped out bad.(Water said nope, and down he sloped.)",
    "Adit, so very tall,Bumped the fan and broke the wall. (His height’s a gift… until ceilings exist.)",
    "Adit, the BBQ king,  Burnt the snags and lost his zing. (Flames went high, now sausages fly.)",

    //ritesh
    "Ritesh, oh Ritesh, he thinks he's Rizztesh but he's Ritech",

    //clifford
    "Clifford, eyes open wide,Typing fast with zero pride. (Sleep is a myth, just one more line… or fifth.)"

        //Avanti
        "Avanti, Asked for water, got ‘wa’er’ instead.(British depression and vowels got harmed.)"

        //Rishi

        "Rishi, always on the go, Writes one line, then says ‘Uh-oh.’ (Fixes none, but claims he’s done.)",

    //Nisha
    "Nisha Misha Dish Pisha Gisha Jisha Yisha Risha Bisa"

        //Sacheth
        "Sacheth’s mustache is so peachy, even peaches are filing a copyright claim.",
    "His hair is so greasy, McDonald's is trying to use it for frying fries.",
    "Every time Sacheth laughs, dolphins in the ocean get confused and start looking for their lost cousin.",
    "If oil prices keep rising, Sacheth’s scalp might become the next major fuel source.",
    "NASA picked up Sacheth’s laugh on their radio signals and thought they discovered an alien species.",
    "Even his mustache is trying to leave his face—it’s just too embarrassed to be there.",
    "His hair is like his future—stuck, messy, and in desperate need of a wash.",

    //Shree k
    "Shree spends more time in Brawl Stars than in real life—someone tell him his social skills need a respawn!",
    "If Shree’s mustache had a job, it’d be the mascot for every corny joke on the internet.",
    "He thinks he’s a Brawl Stars pro, but the only thing he’s good at is getting bullied in every match.",
    "Shree plays Brawl Stars like he’s on a 5-year-old's account—never gets any better, always stuck in low ranks.",
    "When Shree joins a Brawl Stars match, it’s like an instant 2v3—his teammates just pray he doesn’t feed the enemy team.",
    "Shree’s tactics are like his hair—completely unorganized and all over the place.",
    "Shree’s strategy with Kenji is simple—run in, miss every attack, then get eliminated while trying to look cool. ",
    "Kenji might be a fighter, but Shree’s gameplay makes him look like a punching bag.",

    //akilan
    "Akilan’s snacks are more valuable to him than his friendships—don’t even think about asking for one, or he’ll act like you’re asking for his last breath. ",
    "Akilan kicks balls in his sleep, but he can’t seem to manage a simple task while he’s awake.",
    "His MacBook's battery life is better than his ability to keep it from crashing every five minutes.",
    "Akilan’s sleep kicks are like his mind—chaotic, unpredictable, and always causing a bit of trouble.",
    "Akilan’s got so much energy, he’s like a high-voltage cable—constantly sparking, but never quite landing anywhere.",

    //ikshita
    "She plays tennis like she’s in slow motion, and plays violin like she’s trying to break every string on purpose.",
    "Ikshita might be short, but her ego’s about 10 feet tall—too bad she can’t see over it. ",
    "Ikshita’s tennis game is so weak, even the ball’s trying to avoid her racket.",
    "She’s so short, when she plays tennis, she’s practically under the net instead of over it.",

    //rishi
    "Rishi’s idea of making a move is sending a ceiling snap instead of actually talking to his crush.",
    "He’s got the lowest ego—so low, even his self-esteem needs a ladder to reach ground level.",
    "He leaves meetings early like he's got somewhere important to be... but we all know he’s just avoiding doing any work.",
    "Rishi’s programming knowledge is like a work in progress—he’s getting there, just needs a bit more time.",

    //laney
    "Laney’s so short, she needs a step stool just to reach her Starbucks order.",
    "She’s obsessed with Starbucks, but I’m pretty sure her cats are the ones actually managing the resources in that mobile game. ",
    "Laney spent money on a mobile game about cats—guess the game’s the only thing getting the ‘purr-fect’ treatment.",
    "Laney’s idea of a balanced diet is a tall latte in one hand and her phone in the other, tracking her Starbucks rewards.",
    "Laney’s jokes are like her phone battery—always dying at the worst moments.",

    //clifford
    "He can program robots, but can’t seem to program himself to remember where he put his water bottle.",
    "He’s always acting like he’s got all the answers, but couldn’t even figure out where his water bottle was in the shop.",
    "Clifford’s idea of exercising is lifting his gaming console to the couch.",
    "Clifford might be obsessed with Rock Band, but Clifford the Big Red Dog could probably rock a real guitar better than he can.",
    "Clifford the Big Red Dog has tons of friends because he’s a big, friendly dog—Clifford here has his Rock Band skills, but not much else to bring to the table.",

    //gunhong
    "Gunhong loves trash talking so much, he probably talks more than he swims—though, I’m sure he’s good at both. ",
    "Gunhong’s dedication to swimming is impressive, but he’s even more dedicated to making everyone feel bad with his trash talk. ",
    "Gunhong eats 1 dog every meal? At this point, he’s probably part of a dog’s worst nightmare.",
    "He’s dedicated to swimming, but I think the only thing he’s really good at floating is his ego.",
    "He doesn’t care about anything, except maybe finishing his dog every meal. G-money’s a man of simple tastes.",

    //avanti
    "She’s always skipping meetings but wants to be a doctor—good luck diagnosing anything when you can’t even diagnose a meeting on your calendar. ",
    "Avanti’s British accent might sound like she knows what she’s talking about, but her ability to show up to meetings says otherwise.",
    "Avanti’s always skipping meetings, but at least she’s got the British accent to make it sound like she’s doing something important. ",
    "Her British accent makes everything sound smarter, but it’s hard to take her seriously when she’s never around for the important stuff. ",
    "Avanti and Gunhong argue more than they actually get anything done—at this point, they should just start a podcast about their beef. ",
    "The only thing more consistent than Avanti skipping meetings is her ongoing beef with Gunhong.",

    //shreevaishnavi
    "Shreevaishnavi wants to be a doctor but spends more time diagnosing which Starbucks drink to get.",
    "Shreevaishnavi’s love for Starbucks is so strong, I’m starting to think her future diagnosis will be 'Addicted to caffeine.'",
    "She buys a drink, sips a little, and tosses it—looks like Starbucks is just an accessory to her, not a necessity.",
    "She’s got the Starbucks addiction, but at least she doesn’t have to finish the drink—because why waste a full cup when you can just waste a few sips? ",
    "Shreevaishnavi’s weird accent shows up like an unexpected plot twist—you never know when it’s coming, but it always leaves you confused",

    //ritesh
    "Ritesh might be programming in his free time, but in class, he’s more of an expert at snoozing than coding.",
    "Ritesh’s girlfriend is AI, but I think he’s the one who needs an upgrade—especially during class when he’s asleep instead of paying attention.",
    "Ritesh says something bad, then immediately takes it back—guess he’s still learning how to program his mouth to stop talking",
    "He sleeps through school, works at night, and lives on coffee—Ritesh is proving that ‘living the dream’ is just an endless loop of caffeine and code.",
    "Ritesh trades sleep for work at night—he’s out here living the ‘sleep is optional’ life, but coffee is mandatory. ",

    //andrew salmopnson
  ];
  return insults[DateTime.now().microsecond % insults.length];
}
