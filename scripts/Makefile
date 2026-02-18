.PHONY: setup seed clean export-logo

export-logo:
	cd .. && flutter test test/export_logo_test.dart --tags export

setup:
	dart pub get

seed: setup
	dart run seed_marketplace.dart

clean:
	rm -rf .dart_tool pubspec.lock
