# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.2.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]


## [1.6.0] - 10-06-2022

### Fixed

- A Tesla result error value has the type `any()`. `Atom.to_string/1` raises when the Tesla error is anything but an atom, causing the telemetry handler to detach. Set the span error message to a reasonable string interpretation of the error.

## [1.5.1] - 15-12-2021

### Fixed

- Convert error reason to string

## [1.5.0] - 15-12-2021

### Added

- Deal with metadata error from Tesla result

## [1.4.0] - 29-11-2021

### Changed

- Send span error when the status code is different from 2xx

## [1.3.0] - 14-07-2021

### Added

- Support for custom resource naming.

### Changed

- Default resource name now is `<method> <req_url>`.

## [1.2.0] - 12-07-2021

### Added

- Support for new telemetry events format

## [1.1.1] - 17-12-2020

## [1.1.0] - 09-12-2020

[Unreleased]: https://github.com/thiamsantos/spandex_tesla/compare/v1.6.0...HEAD
[1.6.0]: https://github.com/thiamsantos/spandex_tesla/releases/tag/v1.6.0
[1.5.1]: https://github.com/thiamsantos/spandex_tesla/releases/tag/v1.5.1
[1.5.0]: https://github.com/thiamsantos/spandex_tesla/releases/tag/v1.5.0
[1.4.0]: https://github.com/thiamsantos/spandex_tesla/releases/tag/v1.4.0
[1.3.0]: https://github.com/thiamsantos/spandex_tesla/releases/tag/v1.3.0
[1.2.0]: https://github.com/thiamsantos/spandex_tesla/releases/tag/v1.2.0
[1.1.1]: https://github.com/thiamsantos/spandex_tesla/releases/tag/v1.1.1
[1.1.0]: https://github.com/thiamsantos/spandex_tesla/releases/tag/v1.1.0
