# `car`

A very minimalistic insanely quick package manager. May also be reffered to as car/tar or glorified tar extractor.
Car is not meant to do hash checks or whatever; it purposely skips them for speed.
It can convert .deb, .pkg.tar.zst and .AppImage packages to Car's own format - .tar.zst.

## The full docs URL on the Redrose docs site

https://docs.redroselinux.org/#/car.md.

## File structure

- `car.nimble` - Nimble config file
- `Version` - the current version, read by Nim at compile time
- `src/` - source
  - `car.nim` - the app entry point
  - `color.nim` - loggers
  - `fsck_symlink_attacks.nim` - a file with a func to prevent symlink attacks
  - `operations/` - commands of car
  - `converters/` - converters for packages of non-car formats, ran by `install`
    - `appimage.nim` - converter for AppImages
    - `debian.nim` - converter for .deb packages

## Maintaining the codebase

As already mentioned above, the `Version` file includes the current version of the
program. However, the `.nimble` file is not automatically synchronized with this;
you must run this command before releasing a new version:

```bash
nimble syncVersion
```
