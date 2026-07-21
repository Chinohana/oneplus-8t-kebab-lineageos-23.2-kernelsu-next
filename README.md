# OnePlus 8T (kebab) LineageOS 23.2 + SukiSU-Ultra

This repository builds the official LineageOS 23.2 kernel for the OnePlus 8T (`kebab`) with SukiSU-Ultra entirely in GitHub Actions.

## Compatibility

- Device: OnePlus 8T (`kebab`)
- ROM base: LineageOS 23.2
- Kernel source: `LineageOS/android_kernel_oneplus_sm8250`, branch `lineage-23.2`
- Kernel: Linux 4.19
- SukiSU-Ultra: `v4.1.3` by default
- Integration: built-in, non-GKI
- KPM: disabled in the stable configuration
- SUSFS: not included

SukiSU-Ultra officially supports manually built legacy kernels from Linux 4.4 onward. This project pins SukiSU-Ultra v4.1.3 and every other upstream input to a full commit SHA in `build.lock`.

Linux 4.19 does not provide `path_umount`, which current SukiSU-Ultra uses for per-app mount namespace cleanup. The workflow applies a small backport before compilation and records all resolved source commits in the artifact.

## Build with GitHub Actions

1. Open **Actions**.
2. Select **Build kebab kernel with SukiSU-Ultra**.
3. Choose **Run workflow**.
4. Keep the defaults for an official LineageOS 23.2 build, or provide explicit source refs.
5. Download the build artifact after the job succeeds.

Every artifact contains:

- `Image`: raw arm64 kernel image
- `kebab-lineage-23.2-sukisu-ultra-*.zip`: AnyKernel3 flashable package
- `build-info.txt`: resolved kernel and SukiSU-Ultra commit SHAs, compiler version, and kernel release
- `kernel.config`: final build configuration
- `SHA256SUMS`: checksums for the raw image and flashable ZIP

## Flashing warning

Unlocking the bootloader and flashing a custom kernel can erase data or make the device unbootable. Back up the current `boot` partition and keep a known-good LineageOS 23.2 boot image available. The ZIP is restricted to `kebab`, but you are responsible for matching it to your installed LineageOS build. Keep fastboot or recovery access available before relying on the kernel.

Install the SukiSU-Ultra manager matching this kernel after flashing. Download the GitHub Actions artifact, extract its outer ZIP, then flash the inner AnyKernel3 ZIP.

## Reproducibility

The workflow defaults to the official LineageOS branch, SukiSU-Ultra `v4.1.3`, and the LineageOS 23.2 Clang revision. The artifact records the exact kernel and SukiSU commits used by each build.

## Upstream projects

- [LineageOS OnePlus sm8250 kernel](https://github.com/LineageOS/android_kernel_oneplus_sm8250)
- [SukiSU-Ultra](https://github.com/SukiSU-Ultra/SukiSU-Ultra)
- [AnyKernel3](https://github.com/osm0sis/AnyKernel3)
