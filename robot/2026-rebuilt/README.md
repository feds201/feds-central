# 2026-rebuilt -- FEDS Team 201 Robot Code

Robot code for the 2026 FIRST Robotics Competition game **REBUILT**. Built with WPILib and GradleRIO, using CTRE Phoenix 6 for swerve drive and AdvantageKit for logging.

## Gradle Commands

Run from the `robot/2026-rebuilt/` directory.

| Command | What it does |
|---|---|
| `./gradlew build` | Compile and run all tests |
| `./gradlew test` | Run tests only |
| `./gradlew deploy` | Deploy robot code to the roboRIO |
| `./gradlew simulateJava` | Run robot code in simulation (opens Glass + Driver Station). Automatically downloads 3D models via Git LFS. |
| `./gradlew simulateJava -PskipFetchModels` | Run simulation without downloading 3D models |
| `./gradlew fetchModels` | Download 3D simulation models from Git LFS |
| `./gradlew clean` | Delete the build directory |
| `./gradlew Glass` | Launch the Glass dashboard tool |
| `./gradlew ShuffleBoard` | Launch the ShuffleBoard dashboard tool |
| `./gradlew SysId` | Launch the SysId characterization tool |
| `./gradlew javadoc` | Generate Javadoc API documentation |
| `./gradlew dependencies` | Display all project dependencies |

Test report is generated at `build/reports/tests/test/index.html`.