## What does Kuth mean?

Kuth means `Kubernetes under the Hood`.
The directory contains the scripts I wrote for [Kubernetes under the Hood](https://github.com/mvallim/kubernetes-under-the-hood)

Those scripts will make testing and optimizing easier.

## Roadmap

Different from the original repo, I did a lot of  improvements:
- Use modern GPT partition, not MBR partition.
- Partition scheme is more sophisticated.
- Debian Image is the latest.
- Kubernete Release is the latest.
- Update some key components - Loadbalancing, Networking, Storage.
- Use preloading rather than cloud-init for speeding.
- Enable the work to be done across multiple infrastructure.
- Additional footprint for easier experiments.

## Reference
- [Scalable and secure access with SSH](https://engineering.fb.com/2016/09/12/security/scalable-and-secure-access-with-ssh/)
- [Alternative Firmware (EFI)](https://docs.oracle.com/en/virtualization/virtualbox/6.0/user/efi.html#efividmode)
- [Switch Debian from legacy to UEFI boot mode](https://blog.getreu.net/projects/legacy-to-uefi-boot/#_create_a_gpt_partition_table)
- [Installation of Debian 11 UEFI on USB stick using 'debootstrap'](https://ivanb.neocities.org/blogs/y2022/debootstrap)
- [Configure Chrony NTP Server on Debian 12/11/10](https://techviewleo.com/how-to-configure-chrony-ntp-server-on-debian/)
- [SecureBoot](https://wiki.debian.org/SecureBoot)
- [build-debian-qemu-image](https://github.com/loz-hurst/build-debian-qemu-image/blob/master/build-debian-image)  
