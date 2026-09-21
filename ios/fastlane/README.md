fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios build_ipa

```sh
[bundle exec] fastlane ios build_ipa
```

Build a signed App Store IPA (no upload)

### ios tf_status

```sh
[bundle exec] fastlane ios tf_status
```

Print TestFlight build processing status

### ios tf_setup_internal

```sh
[bundle exec] fastlane ios tf_setup_internal
```

Create an internal TestFlight group and add the account holder

### ios beta

```sh
[bundle exec] fastlane ios beta
```

Build a signed IPA and upload it to TestFlight / App Store Connect

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
