# robot-testing-utility — FRC Robot Test Harness

Standalone reusable Java library that auto-discovers and runs annotated test methods on WPILib `SubsystemBase` classes when the robot enters **Test mode** in the Driver Station.

Originally built for the **2026 REBUILT** robot. Packaged here so any FRC team can drop it in.

---

## Module Structure

```
src/main/java/frc/rtu/
├── RobotAction.java          @RobotAction annotation — mark methods as tests
├── RootTestingUtility.java   Discovery, execution, AK logging, dashboard updates
├── TestResult.java           Immutable result record (status, duration, alerts, profiles)
├── DiagnosticContext.java    Injected into tests for alerts and data samples
├── DiagnosticServer.java     Embedded HTTP dashboard (port 5800, Chart.js charts)
│
└── example/
    └── ExampleTestSubsystem.java   Reference implementation showing all features
```

---

## Quick Start (3 steps)

### 1. Add the dependency

In your robot project's `settings.gradle`, include the library:

```groovy
include ':robot-testing-utility'
project(':robot-testing-utility').projectDir = new File(settingsDir, '../robot-testing-utility')
```

In `build.gradle`:

```groovy
dependencies {
    implementation project(':robot-testing-utility')
}
```

### 2. Write `@RobotAction` methods in your subsystems

```java
import frc.rtu.RobotAction;
import frc.rtu.DiagnosticContext;

public class MySubsystem extends SubsystemBase {

    @RobotAction(name = "Motor Connected", description = "CAN bus check", order = 1)
    public boolean testMotorConnected() {
        return motor.isConnected();
    }

    @RobotAction(name = "Motor Spins", description = "Apply voltage and verify movement", order = 2)
    public boolean testMotorSpins(DiagnosticContext ctx) {
        ctx.info("Applying 2V...");
        motor.setControl(new VoltageOut(2.0));
        Timer.delay(0.5);
        double vel = motor.getVelocity().getValueAsDouble();
        motor.setControl(new VoltageOut(0));
        if (Math.abs(vel) < 0.1) { ctx.error("Motor did not move!"); return false; }
        return true;
    }
}
```

### 3. Register and wire

```java
// RobotContainer
private final RootTestingUtility rootTester = new RootTestingUtility();

private void configureRootTests() {
    rootTester.registerSubsystem(intake, shooter, climber);

    // Optional: require driver to hold both triggers before tests run
    rootTester.setSafetyCheck(() ->
        ctrl.getLeftTriggerAxis() > 0.5 && ctrl.getRightTriggerAxis() > 0.5
            ? null : "Hold both triggers to start tests"
    );
}

// Robot.java
@Override public void testInit()     { m_robotContainer.runRootTests(); }
@Override public void testPeriodic() { m_robotContainer.updateRootTests(); }
```

---

## `@RobotAction` Reference

| Property | Type | Default | Description |
|---|---|---|---|
| `name` | String | method name | Human-readable test name |
| `description` | String | `""` | What this test validates |
| `order` | int | `MAX_VALUE` | Execution order (lower = first) |
| `timeoutSeconds` | double | `5.0` | Max runtime before auto `TIMED_OUT` |

**Method signatures accepted:**

```java
public boolean myTest()                        // true = PASS, false = FAIL
public void myTest()                           // PASS if no exception
public boolean myTest(DiagnosticContext ctx)   // same + alerts/profiles
public void myTest(DiagnosticContext ctx)      // same + alerts/profiles
```

---

## DiagnosticContext

```java
ctx.info("message");               // INFO alert
ctx.warn("message");               // WARNING alert
ctx.error("message");              // ERROR alert
ctx.sample("series name", value);  // record numeric data point (auto-timestamped)
ctx.sample("series name", ms, v);  // record with explicit relative timestamp
```

Data samples are plotted as **Chart.js line charts** on the live dashboard.

---

## Result Statuses

| Status | Meaning |
|---|---|
| `PASSED` | Test returned `true` or completed without throwing |
| `FAILED` | Test returned `false`, threw an exception, or safety check failed |
| `TIMED_OUT` | Test exceeded `timeoutSeconds` |

---

## Live Dashboard

Automatically starts at `http://<roboRIO-ip>:5800/diag/<session>` when `runAll()` is called. Exact URL is printed in the console.

- **Auto-refreshes** every 3 seconds
- Shows summary bar, per-test cards, alerts, and data profile charts
- JSON API at `/diag/<session>/json` for programmatic access
- Port 5800 is within the FRC field firewall range — works at competition

---

## AdvantageKit Integration

If AK is on the classpath, results are published under `RootTests/` in the log. The library works **without AK** — Logger calls are silently skipped.

---

## Gradle Commands

Run from `robot/robot-testing-utility/`:

| Command | What it does |
|---|---|
| `./gradlew build` | Compile + run all tests |
| `./gradlew test` | Run unit tests only |
| `./gradlew jar` | Build the standalone JAR |
| `./gradlew javadoc` | Generate Javadoc |

Test report: `build/reports/tests/test/index.html`

---

## Releasing

Push a tag matching `rtu/v*` (e.g. `rtu/v1.0.0`) to trigger the GitHub Actions release workflow. The JAR will be attached to a GitHub Release automatically.

```bash
git tag rtu/v1.0.0
git push origin rtu/v1.0.0
```

---

## Dependencies

| Dependency | Version | Purpose |
|---|---|---|
| WPILib | 2026.1.1 | `SubsystemBase` and robot framework |
| AdvantageKit | 4.1.0 | Optional telemetry (compileOnly) |
| JUnit 5 | 5.10.1 | Testing |

Java 17 required.
