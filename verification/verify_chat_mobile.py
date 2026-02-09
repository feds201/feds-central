from playwright.sync_api import sync_playwright, expect

def run(playwright):
    browser = playwright.chromium.launch(headless=True)
    # Emulate iPhone 12
    iphone_12 = playwright.devices['iPhone 12']
    context = browser.new_context(**iphone_12)
    page = context.new_page()

    # Go to chat page
    print("Navigating to chat page...")
    page.goto("http://localhost:5173/chat")

    # Wait for page to load
    # page.wait_for_load_state("networkidle")

    # Check if we are on chat page (look for "Chat" header which I added)
    print("Checking if we are on chat page...")
    # The header has "Chat" text
    expect(page.get_by_text("Chat", exact=True)).to_be_visible()

    # Check if menu button is visible (it should be on mobile)
    print("Checking for menu button...")
    # Target the button inside the chat card
    # The Chat component uses 'glass-card' class.
    menu_button = page.locator(".glass-card button:has(svg.lucide-menu)")
    expect(menu_button).to_be_visible()

    # Check if sidebar is hidden.
    print("Checking backdrop is not visible...")
    backdrop = page.locator(".fixed.inset-0.bg-black\/60")
    expect(backdrop).not_to_be_visible()

    # Take screenshot before opening sidebar
    page.screenshot(path="/home/jules/verification/chat_mobile_closed.png")
    print("Screenshot taken: chat_mobile_closed.png")

    # Click menu button
    print("Clicking menu button...")
    menu_button.click()

    # Check if sidebar is now open (backdrop visible)
    print("Checking backdrop is visible...")
    expect(backdrop).to_be_visible()

    # Take screenshot after opening sidebar
    page.screenshot(path="/home/jules/verification/chat_mobile_open.png")
    print("Screenshot taken: chat_mobile_open.png")

    browser.close()

with sync_playwright() as playwright:
    run(playwright)
