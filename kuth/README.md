## What does Kuth mean?

Kuth means `Kubernetes under the Hood`.
The directory contains the scripts I wrote for [Kubernetes under the Hood](https://github.com/mvallim/kubernetes-under-the-hood)

Those scripts will make testing and optimizing easier.

## Roadmap

Different from the original repo, I did a lot of improvements:
- Use modern GPT partition, not MBR partition. Status: DONE.
- Partition scheme is more sophisticated - A/B partition.
- Debian image is the latest, bookworm. Status: DONE.
- Kubernete release is the latest 1.29. Status: DONE.
- Update some key components - Loadbalancing, Networking, Storage.
- Load balancing, use keepalived and haproxy instead.
- Networking - use Cilium instead
- Image, use mkosi instead, not debootstrap
- Use preloading rather than cloud-init for speeding.
- Enable the work to be done across multiple infrastructure.
- Additional footprint for easier experiments.
- Flexible cluster architecture: 1 node, 3 node, 1+1 node, 3+1 node
- Control Plane and Data plan are in different networks.

## References
### Secure Boot
- [SecureBoot](https://wiki.debian.org/SecureBoot)

### Vulnerability
- [NVM APIs](https://nvd.nist.gov/developers/vulnerabilities)
- [Debian Security Tracker](https://security-team.debian.org/security_tracker.html)

### Certificate
- [OpenSSL Tutorial](https://www.cs.toronto.edu/~arnold/427/19s/427_19S/tool/ssl/notes.pdf)
- [OpenSSL PKI Tutorial v1.1](https://pki-tutorial.readthedocs.io/en/latest/#)
- [OpenSSL Certificate Authority](https://jamielinux.com/docs/openssl-certificate-authority/)

### SSH
- [SSH CA host and user certificates](https://liw.fi/sshca/)
- [How to Generate and Configure SSH Certificate-Based Authentication](https://goteleport.com/blog/how-to-configure-ssh-certificate-based-authentication/)
- [SSH Certificates Security](https://goteleport.com/blog/ssh-certificates/)
- [Scalable and secure access with SSH](https://engineering.fb.com/2016/09/12/security/scalable-and-secure-access-with-ssh/)

### Logging, Metrics, Traces and Events
- [Prometheus](https://prometheus.io)
- [Fluentbit](https://docs.fluentbit.io/manual/administration/configuring-fluent-bit)

### EFI
- [Alternative Firmware (EFI)](https://docs.oracle.com/en/virtualization/virtualbox/6.0/user/efi.html#efividmode)
- [Switch Debian from legacy to UEFI boot mode](https://blog.getreu.net/projects/legacy-to-uefi-boot/#_create_a_gpt_partition_table)
- [Installation of Debian 11 UEFI on USB stick using 'debootstrap'](https://ivanb.neocities.org/blogs/y2022/debootstrap)
- [Configure Chrony NTP Server on Debian 12/11/10](https://techviewleo.com/how-to-configure-chrony-ntp-server-on-debian/)
- [build-debian-qemu-image](https://github.com/loz-hurst/build-debian-qemu-image/blob/master/build-debian-image)

### APIs
- [LDAP Apis](https://ldap.com/client-apis/)
