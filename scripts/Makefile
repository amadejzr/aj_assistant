.PHONY: setup seed clean

setup:
	dart pub get

seed: setup
	dart run seed_marketplace.dart

clean:
	rm -rf .dart_tool pubspec.lock
