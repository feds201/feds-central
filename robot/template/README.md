# Robot Template Code -- FEDS Team 201 Robot Code

Template robot code 20XX FIRST Robotics Competition game **GAME_NAME_HERE**. Built with WPILib and GradleRIO, using CTRE Phoenix 6 for swerve drive and AdvantageKit for logging.

## Gradle Commands

Run from the `robot/20xx-<game>/` directory.

| Command | What it does |
|---|---|
| `./gradlew build` | Compile and run all tests |
| `./gradlew test` | Run tests only |
| `./gradlew deploy` | Deploy robot code to the roboRIO |
| `./gradlew simulateJava` | Run robot code in simulation (opens Glass + Driver Station) |
| `./gradlew clean` | Delete the build directory |
| `./gradlew Glass` | Launch the Glass dashboard tool |
| `./gradlew ShuffleBoard` | Launch the ShuffleBoard dashboard tool |
| `./gradlew SysId` | Launch the SysId characterization tool |
| `./gradlew javadoc` | Generate Javadoc API documentation |
| `./gradlew dependencies` | Display all project dependencies |

Test report is generated at `build/reports/tests/test/index.html`.

## Dependencies

This project includes [sim-core](../sim-core/) as a composite build for physics simulation. See `settings.gradle` for the include.
