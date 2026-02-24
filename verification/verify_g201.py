from playwright.sync_api import sync_playwright

def run(playwright):
    browser = playwright.chromium.launch(headless=True)
    page = browser.new_page()
    page.goto("http://localhost:8000")

    print(page.title())

    # Click start button for module 1
    page.click(".module1 .start-btn")

    # Verify first question appears
    page.wait_for_selector(".question-card:not(.hidden)")

    # Answer first question (Int)
    page.fill("#answer-input", "500")
    page.click("#next-btn")

    # Verify second question appears (MC)
    page.wait_for_selector("#mc-container:not(.hidden)")

    # Select first option
    page.check("input[name='mc-answer'][value='0']")
    page.click("#next-btn")

    # Verify third question appears (MC)
    page.wait_for_selector("#mc-container:not(.hidden)")

    # Select first option
    page.check("input[name='mc-answer'][value='0']")
    page.click("#next-btn")

    # Verify fourth question appears (MC)
    page.wait_for_selector("#mc-container:not(.hidden)")

    # Select first option
    page.check("input[name='mc-answer'][value='0']")
    page.click("#next-btn")

    # Now it should finish quiz and show results
    page.wait_for_selector("#result:not(.hidden)")

    # Take screenshot of results
    page.screenshot(path="verification/g201_results.png")

    browser.close()

with sync_playwright() as playwright:
    run(playwright)
