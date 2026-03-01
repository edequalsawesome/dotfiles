---
name: orbstack-sparse-file-corruption
description: |
  Fix OrbStack startup failures with "not enough space" or I/O errors when data is stored
  on external drives. Use when: (1) OrbStack crashes immediately after boot with I/O errors,
  (2) logs show "No such file or directory" errors at specific disk offsets, (3) OrbStack
  complains about space but the drive has plenty free, (4) data.img.raw is on an external
  SSD/HDD. Root cause is APFS sparse file extent corruption, not actual space issues.
author: Claude Code
version: 1.0.0
date: 2026-02-28
---

# OrbStack Sparse File Corruption on External Drives

## Problem

OrbStack fails to start with I/O errors or misleading "not enough space" messages when its
data directory is on an external drive. The VM boots but crashes within seconds.

## Context / Trigger Conditions

- OrbStack data directory configured to external SSD/HDD (check `~/.orbstack/vmconfig.json`)
- Logs show: `block req failed: write failed @ [offset]: No such file or directory`
- Kernel logs show: `BTRFS error (device vdb1): bdev /dev/vdb1 errs: wr X`
- The `data.img.raw` file exists and appears normal with `ls`
- External drive was possibly disconnected while OrbStack was running
- System crash or power loss while OrbStack was writing

## Diagnosis

### Step 1: Verify the sparse file location

```bash
cat ~/.orbstack/vmconfig.json
# Shows: {"data_dir": "/Volumes/YourDrive/Orbstack"}
```

### Step 2: Check apparent vs actual size

```bash
ls -lah /Volumes/YourDrive/Orbstack/data.img.raw  # Shows 8.0T (apparent)
du -sh /Volumes/YourDrive/Orbstack/data.img.raw   # Shows actual usage (e.g., 6.8G)
```

### Step 3: Find the corruption point

The key insight: "No such file or directory" when reading/writing an existing file means
the sparse file's extent metadata is corrupted at that location.

```python
# Save as test_sparse.py and run with: python3 test_sparse.py
import os
path = '/Volumes/YourDrive/Orbstack/data.img.raw'
f = open(path, 'rb')

# Binary search for the failing offset
low, high = 0, 50*1024*1024  # Start searching 0-50MB
while high - low > 4096:
    mid = (low + high) // 2
    f.seek(mid)
    try:
        f.read(512)
        low = mid
    except:
        high = mid
        f = open(path, 'rb')  # Reopen after failure

print(f'Corruption starts at offset: {high} ({high/(1024*1024):.2f} MB)')
```

### Step 4: Verify with OrbStack logs

```bash
tail -100 ~/.orbstack/log/*.log | grep -E "ERROR|error|failed"
# Look for: "write failed @ 48119808" or similar offset
```

## Solution

### Option A: Repair APFS (may fix it)

```bash
# Unmount the volume
diskutil unmount "/Volumes/YourDrive"

# Run fsck on the APFS CONTAINER (not volume) with repair
sudo fsck_apfs -y /dev/diskN  # N = container disk number, check with: diskutil list
```

This fixes overallocation and orphan extent issues but may leave a small unrecoverable gap.

### Option B: Reset OrbStack data (guaranteed fix)

If repair doesn't work or you don't care about existing containers:

```bash
# Delete corrupted files
rm -f "/Volumes/YourDrive/Orbstack/data.img.raw"
rm -f "/Volumes/YourDrive/Orbstack/swap.img"

# Restart OrbStack - it will create fresh files
open -a OrbStack
```

You'll need to re-pull images and recreate containers.

## Verification

After fix, verify the sparse file is healthy:

```bash
python3 -c "
f = open('/Volumes/YourDrive/Orbstack/data.img.raw', 'rb')
for offset in [0, 48119808, 100*1024*1024]:  # Test problem areas
    f.seek(offset)
    f.read(512)
    print(f'Offset {offset}: OK')
f.close()
print('Sparse file is healthy!')
"
```

And check OrbStack status:

```bash
orb status  # Should show: Running
docker ps   # Should work without errors
```

## Root Cause

APFS sparse files store extent metadata that maps logical offsets to physical blocks. When:
1. External drive is disconnected during write operations
2. System crashes while OrbStack is writing
3. APFS metadata becomes inconsistent

...the extent map can get corrupted. This creates "holes" where the file exists but specific
regions can't be read/written. The error "No such file or directory" is misleading - it means
the extent metadata for that region is gone, not that the file doesn't exist.

## Prevention

- Always properly stop OrbStack before disconnecting external drives: `orb stop`
- Use "Eject" in Finder before physically disconnecting
- Consider keeping OrbStack data on internal storage for reliability
- Run periodic APFS checks: `diskutil verifyVolume /Volumes/YourDrive`

## Notes

- The 8TB apparent size of data.img.raw is intentional (sparse file) - actual usage is much smaller
- OrbStack's internal filesystem is BTRFS, which has its own error recovery but can't help if the underlying APFS is corrupted
- fsck_apfs may report "appears to be OK" even with remaining gaps if it fixed what it could
- The corruption often occurs at specific sectors where BTRFS stores transaction logs

## References

- [OrbStack Data Directory Documentation](https://docs.orbstack.dev/settings#data-directory)
- [Apple APFS Sparse File Behavior](https://developer.apple.com/documentation/foundation/file_system/about_apple_file_system)
