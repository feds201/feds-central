# Code Guard Review for PR #34

As a Code Guard, I have reviewed the changes in this PR and identified several opportunities to improve maintainability, security, and readability.

## Findings

1.  **Manual JSON Construction**
    *   **File:** `robot/2026-rebuilt/src/main/java/frc/robot/utils/RTU/DiagnosticServer.java`
    *   **Line:** 224
    *   **Issue:** Constructing JSON strings manually using `StringBuilder` is error-prone and brittle. It requires manual escaping which can easily miss edge cases.
    *   **Recommendation:** Use a standard library like `Jackson` (available via WPILib) or `Gson` to serialize objects to JSON.

2.  **Manual HTML Construction**
    *   **File:** `robot/2026-rebuilt/src/main/java/frc/robot/utils/RTU/DiagnosticServer.java`
    *   **Line:** 110
    *   **Issue:** Manually building HTML strings in Java code mixes logic with presentation and is hard to read/maintain.
    *   **Recommendation:** Consider using a simple template engine or loading a static HTML file and replacing placeholders.

3.  **Unclosed ExecutorService**
    *   **File:** `robot/2026-rebuilt/src/main/java/frc/robot/utils/RTU/RootTestingUtility.java`
    *   **Line:** 74
    *   **Issue:** The `ExecutorService` is created but never shut down. This could lead to thread leaks if the utility is re-instantiated.
    *   **Recommendation:** Implement a `close()` or `shutdown()` method.

4.  **Busy Wait in Test Loop**
    *   **File:** `robot/2026-rebuilt/src/main/java/frc/robot/utils/RTU/RootTestingUtility.java`
    *   **Line:** 201
    *   **Issue:** Using `Thread.sleep(50)` in a `while` loop creates a busy-wait.
    *   **Recommendation:** Verify this is intended or consider a scheduled executor/wait-notify pattern.

5.  **Confusing Safety Check Message**
    *   **File:** `robot/2026-rebuilt/src/main/java/frc/robot/RobotContainer.java`
    *   **Line:** 186
    *   **Issue:** The message "Did not receive start command..." implies the test never started, even if it appears during a running test (acting as a dead-man switch).
    *   **Recommendation:** Update to "Safety switch released - holding triggers required to continue tests".

6.  **Build Failure**
    *   **File:** `robot/2026-rebuilt/build.gradle`
    *   **Line:** 62
    *   **Issue:** Local build fails with `Cannot expand ZIP '/app/robot/sim-core/build/libs/sim-core-1.0-SNAPSHOT.jar' as it does not exist`.
    *   **Recommendation:** Verify the `sim-core` project dependency configuration and ensure the `jar` task runs correctly for `sim-core`.

## automated_review_script.sh

Run this script to post the inline comments to the PR (requires `GITHUB_TOKEN`):

```bash
#!/bin/bash

# Check for GITHUB_TOKEN
if [ -z "$GITHUB_TOKEN" ]; then
  echo "Error: GITHUB_TOKEN is not set."
  echo "Please export GITHUB_TOKEN='your_token_here' and run this script again."
  exit 1
fi

REPO="feds201/feds-central"
PR_NUMBER="34"

read -r -d '' DATA << EOM
{
  "event": "COMMENT",
  "body": "As a CodeGuard, here is my review of the changes. I have identified several opportunities to improve maintainability, security, and readability.",
  "comments": [
    {
      "path": "robot/2026-rebuilt/src/main/java/frc/robot/utils/RTU/DiagnosticServer.java",
      "line": 224,
      "body": "As a CodeGuard, here are my suggestions:\n\nConstructing JSON strings manually using \`StringBuilder\` is error-prone and brittle. It requires manual escaping which can easily miss edge cases (e.g. control characters).\n\n**Recommendation:** Use a standard library like \`Jackson\` (available via WPILib) or \`Gson\` to serialize objects to JSON. This ensures correct escaping and is much more maintainable."
    },
    {
      "path": "robot/2026-rebuilt/src/main/java/frc/robot/utils/RTU/DiagnosticServer.java",
      "line": 110,
      "body": "As a CodeGuard, here are my suggestions:\n\nManually building HTML strings in Java code mixes logic with presentation and is hard to read/maintain. It is also prone to XSS if escaping is missed.\n\n**Recommendation:** Consider using a simple template engine (e.g. Mustache, Velocity) or even loading a static HTML file and replacing placeholders. If you must generate it in code, ensure all dynamic data is rigorously escaped."
    },
    {
      "path": "robot/2026-rebuilt/src/main/java/frc/robot/utils/RTU/RootTestingUtility.java",
      "line": 74,
      "body": "As a CodeGuard, here are my suggestions:\n\nThe \`ExecutorService\` is created here but never shut down. If the \`RootTestingUtility\` is instantiated multiple times or the robot code restarts (in simulation or unit tests), this could lead to thread leaks.\n\n**Recommendation:** Implement a \`close()\` or \`shutdown()\` method to properly shut down the executor when the utility is no longer needed."
    },
    {
      "path": "robot/2026-rebuilt/src/main/java/frc/robot/utils/RTU/RootTestingUtility.java",
      "line": 201,
      "body": "As a CodeGuard, here are my suggestions:\n\nUsing \`Thread.sleep(50)\` in a \`while\` loop creates a busy-wait. While this runs in a dedicated test thread, it blocks that thread efficiently.\n\n**Recommendation:** Ensure this blocking behavior is intended. For a smoother implementation, you might consider a scheduled check or a wait/notify mechanism, though for this specific use case, it is acceptable if documented."
    },
     {
      "path": "robot/2026-rebuilt/src/main/java/frc/robot/RobotContainer.java",
      "line": 186,
      "body": "As a CodeGuard, here are my suggestions:\n\nThe safety check error message 'Did not receive start command...' might be confusing if it appears during a running test (acting as a dead-man switch). It implies the test never started.\n\n**Recommendation:** Update the message to clearer, e.g., 'Safety switch released - holding triggers required to continue tests'."
    },
    {
      "path": "robot/2026-rebuilt/build.gradle",
      "line": 62,
      "body": "As a CodeGuard, here are my suggestions:\n\nThe build fails locally with \`Cannot expand ZIP ... sim-core-1.0-SNAPSHOT.jar\`. This suggests the \`sim-core\` project JAR is not being built correctly before the main project tries to use it.\n\n**Recommendation:** Verify the \`sim-core\` build configuration and task dependencies."
    }
  ]
}
EOM

curl -L \
  -X POST \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer \$GITHUB_TOKEN" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/repos/\$REPO/pulls/\$PR_NUMBER/reviews \
  -d "\$DATA"
```
