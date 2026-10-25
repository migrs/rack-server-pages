# Releasing Rack Server Pages

Release bug fixes frequently, features less frequently, and breaking changes rarely.

## Release

Start from a clean, up-to-date canonical checkout on `master`. Confirm that `origin` points to `migrs/rack-server-pages`, the version in `lib/rack-server-pages/version.rb` matches the next heading in [CHANGES.md](CHANGES.md), and the version has not already been tagged or published to RubyGems.

```sh
git switch master
git pull --ff-only origin master
git status --short
```

Run lint and the complete test suite with Firefox available. Selenium manages its driver; use headless mode locally. See [Development](README.md#development) for dependency setup.

```sh
MOZ_HEADLESS=1 bundle exec rake
```

Also run the suite against Rack 2.2. The `RACK_VERSION` selector must be set when resolving dependencies and running tests:

```sh
RACK_VERSION='~> 2.2' bundle update rack rackup
RACK_VERSION='~> 2.2' MOZ_HEADLESS=1 bundle exec rake spec
```

Return to the default Rack 3 dependencies afterward:

```sh
bundle update rack rackup
```

Review [UPGRADING.md](UPGRADING.md) for behavior changes. Replace `Next` in the release heading in `CHANGES.md` with the current date, preserving the existing `YYYY-MM-DD` format. Commit and push the release preparation:

```sh
git add CHANGES.md
git commit -m "Preparing for release, 0.3.0."
git push origin master
```

Wait for the release commit's [GitHub Actions](https://github.com/migrs/rack-server-pages/actions) checks to pass across the full Ruby/Rack matrix and lint. A successful build for a different commit is not sufficient.

Publishing requires a maintainer's RubyGems credentials and may require a fresh one-time password (OTP). For an agent-assisted release, request the OTP immediately before publishing, after validation and CI complete. Never commit or log credentials or OTPs. With `OTP` holding a freshly supplied code:

```sh
GEM_HOST_OTP_CODE="$OTP" bundle exec rake release
unset OTP
```

Bundler builds the gem in `pkg/`, creates the version tag, pushes the commit and tag, and publishes the gem. Verify that the remote tag points to the release commit and RubyGems lists the expected version. If a step fails, inspect what completed before retrying; never move a published release tag or overwrite a published version.

Create a GitHub release from the tag, using the corresponding changelog entry as release notes and linking to the upgrade guide for behavior changes:

```sh
gh release create v0.3.0 --verify-tag --title "v0.3.0" --notes-file /path/to/release-notes.md
```

## Prepare the Next Version

Increment the patch version in `lib/rack-server-pages/version.rb`, then add a new `Next` section at the top of `CHANGES.md`, updating both its release and comparison links:

```markdown
### [v0.3.1](https://github.com/migrs/rack-server-pages/releases/tag/v0.3.1) / Next

  * [Changes](https://github.com/migrs/rack-server-pages/compare/v0.3.0...v0.3.1)

  * Feature

  * Bugfix

  * Misc
```

```sh
git add CHANGES.md lib/rack-server-pages/version.rb
git commit -m "Preparing for next development iteration, 0.3.1."
git push origin master
```
