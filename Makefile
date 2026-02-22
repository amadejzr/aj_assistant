.PHONY: screenshots screenshot-home screenshot-chat screenshot-marketplace screenshot-expense-tracker showcase showcase-render

DRIVER = test_driver/screenshot_test.dart
DEVICE_FLAG = $(if $(DEVICE),-d $(DEVICE),)

# All screenshots in one install
screenshots:
	flutter drive --driver=$(DRIVER) --target=integration_test/all_screenshots_test.dart $(DEVICE_FLAG)

# Individual screenshots (separate installs)
screenshot-home:
	flutter drive --driver=$(DRIVER) --target=integration_test/home_test.dart $(DEVICE_FLAG)

screenshot-chat:
	flutter drive --driver=$(DRIVER) --target=integration_test/chat_test.dart $(DEVICE_FLAG)

screenshot-marketplace:
	flutter drive --driver=$(DRIVER) --target=integration_test/marketplace_test.dart $(DEVICE_FLAG)

screenshot-expense-tracker:
	flutter drive --driver=$(DRIVER) --target=integration_test/expense_tracker_test.dart $(DEVICE_FLAG)

showcase-render:
	"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
		--headless=new \
		--screenshot=docs/screenshots/showcase.png \
		--window-size=1200,900 \
		--force-device-scale-factor=2 \
		"file://$(CURDIR)/docs/screenshots/showcase.html"
	@echo "Showcase saved to docs/screenshots/showcase.png"

showcase: screenshots showcase-render
