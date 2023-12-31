# Disk Layout

# Paritition
```
 1 EFI-SYSTEM  Bootloader FAT32      256M
 2 ROOT-A      Root filesystem  EXT2 5G
 3 ROOT-B      Root filesystem  EXT2 5G
 4 CFG         Configuration    EXT4 128M
 5 DATA1        Data partition  EXT4 5G // For container image or customer installed application
 6 DATA2        Data partition  EXT4 5G // For obeservility metrics
 7 LOG         Log partition    EXT4 10G
```

```shell
parted -s -a optimal -- ${RAW_DEBIAN_IMAGE_PATH} \
        mklabel gpt \
        mkpart primary fat32 1MiB 256MiB \
        mkpart primary ext2  256MiB 5376MiB \
        mkpart primary ext2  5376MiB 10490MiB \
        mkpart primary ext4  10490MiB 10624MiB  \
        mkpart primary ext4  10624MiB 15744MiB\
        mkpart primary ext4  15744GiB 20864MiB\
        mkpart primary ext4  20864MiB  \
        set 1 esp on
```
