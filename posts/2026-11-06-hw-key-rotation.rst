---
title: "A Recipe for Managing USB Security Keys"
---

=======================================
A Recipe for Managing USB Security Keys
=======================================

  A guide to back up and renew OpenPGP keys stored on hardware security devices, such as 
  YubiKey and Nitrokey.

**Table of Contents:**

* `Introduction`_
* `Planning`_
* `Creating the Initial Backup`_
* `Transferring Keys to the Security Device`_
* `Renewing Subkeys`_

Introduction
============

OpenPGP private keys are stored directly on the device, and there is no way to extract
them. The approach here will be to make a secure backup on offline storage, then transfer
the keys to the security device. This guide demonstrates how to make the initial backup,
transfer the keys to the card, and renew them after expiration.

There are already excellent guides on this subject (see DrDuh's `Yubikey Guide`_, `Nitrokey
Documentation`_, and `YubiKey Documentation`_). However, this recipe takes a slightly
different approach:

**GNUPGHOME is NOT stored on backup storage**: It's convenient to place an isolated GPG home 
directory on backup storage, but it gets messy over time. Instead, keys are imported each time
you mount the backup USB device.

**Keys are stored in a local Git repository**: Storing current keys alongside
outdated/expired ones (with a date suffix, say ``private-20261101.key``) also gets
messy over time. Instead, only the current keys are stored in the directory tree, but any
key can be accessed from git history.

**USB backup storage is written to a local image**: Sometimes when working on USB devices,
they lose connection, and the whole process has to be restarted. For that reason, the
device is copied to a local image, then mounted. Afterward, the image is then written back
to USB media. If the connection is lost, the data is intact. This also makes it easy to
write multiple backups.

.. _Yubikey Guide: https://github.com/drduh/YubiKey-Guide
.. _Nitrokey Documentation: https://docs.nitrokey.com/nitrokeys/features/openpgp-card/overview
.. _Yubikey Documentation: https://support.yubico.com/s/article/Using-Your-YubiKey-with-OpenPGP

.. note:: This guide assumes you already have key pairs that will be (or already have been) 
   transferred to the security key. You should have a certify key, along with subkeys for
   signing, encryption, and authentication. If not, follow the directions in the
   `Yubikey Guide`_ or `Nitrokey Documentation`_.

`Planning`
===========

Before starting, you need settle on a directory structure for your backup keys. This is
what I decided on::

    + personal/                        # Personal identities (sean@mistersg.net)
      - sean-gillespie.asc             # Public key
      - sean-gillespie-full.key        # Full secret key (certify and subkeys)
      - sean-gillespie-subkeys.key     # Secret subkeys (excluding the certify key)
    + work/                            # Work identities (sean@icangroup.co.uk)
      - sean-gillespie-iog.asc         # Public key
      - sean-gillespie-iog-full.key    # Full secret key (certify and subkeys)
      - sean-gillespie-iog-subkeys.key # Secret subkeys (excluding the certify key)
    + retired/                         # All identities no longer used (by "0xlong" keyid)
      - 0x02E9A9C5EF7F23AB.asc         # Retired public key
      - 0x02E9A9C5EF7F23AB-full.key    # Retired full secret key
      - 0x02E9A9C5EF7F23AB-subkeys.key # Retired subkeys

I also recommend including a ``README.md`` with reference instructions on updating keys.

`Creating the Initial Backup`
==============================

First, insert a USB storage device and locate it::

    lsblk

    NAME                           MAJ:MIN RM   SIZE RO TYPE  MOUNTPOINTS
    # <-- Snip -->
    sda                              8:0    1  14.6G  0 disk

This example shows ``/dev/sda``, which we'll use throughout this guide. Next, securely
erase it::

    sudo dd if=/dev/zero of=/dev/sda bs=4M status=progress

Create a new GPT partition table::

    sudo parted /dev/sda

    mklabel gpt
    quit

Reconnect the device and create a partition for storing backups::

    sudo parted /dev/sda
    mkpart ext2 2048s 8G
    quit

Since we'll write the encrypted image to tmpfs, I've deliberately made it small 
enough to fit in memory.

Generate a unique passphrase for the LUKS volume::

    nix shell github:sgillespie/gibberish\#gibberish:exe:gibber \
      --accept-flake-config \
      --command gibber --digits --capitals --symbols 10
    # Copy one from the list and save it
    export LUKS_PASS='CHANGEME'

Format the partition using the passphrase from above::

    sudo cryptsetup luksFormat /dev/sda1
    sudo systemd-cryptsetup attach hwkeys /dev/sda1
    sudo mkfs.ext2 /dev/mapper/hwkeys -L hwkeys

Detach it and create a local image of the encrypted drive::

    sudo systemd-cryptsetup detach hwkeys
    sudo dd bs=4M status=progress conv=fsync oflag=direct \
      of="/tmp/hwkeys.img" \
      if=/dev/sda1

Unlock and mount the image::

    sudo systemd-cryptsetup attach hwkeys-img /tmp/hwkeys.img
    sudo mount /dev/mapper/hwkeys-img /mnt

Initialize a local git repository::

    sudo chown -R "$(id -un):$(id -gn)" /mnt
    cd /mnt
    git init
    mkdir personal work retired

Export your existing keys::

    # Personal identities
    gpg --armor --export --output personal/sean-gillespie.asc $KEY_ID
    gpg --armor --export-secret-keys personal/sean-gillespie-full.key $KEY_ID
    gpg --armor --export-secret-subkeys personal/sean-gillespie-subkeys.key $KEY_ID

    # Work identities
    gpg --armor --export --output work/sean-gillespie-iog.asc $KEY_ID
    gpg --armor --export-secret-keys work/sean-gillespie-iog-full.key $KEY_ID
    gpg --armor --export-secret-subkeys work/sean-gillespie-iog-subkeys.key $KEY_ID

    # Retired/expired identities
    gpg --armor --export --output retired/$KEY_ID.asc $KEY_ID
    gpg --armor --export-secret-keys retired/$KEY_ID-full.key $KEY_ID
    gpg --armor --export-secret-subkeys retired/$KEY_ID-subkeys.key $KEY_ID

Stage files and commit::

    git add personal work retired
    git commit

Unmount and write the image to USB media::

    umount /mnt
    sudo systemd-cryptsetup detach hwkeys-img

    # Double check this command and make darned sure you are writing to the correct 
    # device!
    sudo dd bs=4M status=progress conv=fsync oflag=direct \
      if="/tmp/hwkeys.img" \
      of=/dev/sda1

    # If desired, repeat on another USB storage device 
    sudo dd bs=4M status=progress conv=fsync oflag=direct \
      if="/tmp/hwkeys.img" \
      of=/dev/sdb1

Make sure you can access the data::

    sudo systemd-cryptsetup attach hwkeys /dev/sda1
    sudo mount /dev/mapper/hwkeys /mnt

Unmount and lock it when you are done::

    sudo umount /mnt
    sudo systemd-cryptsetup detach hwkeys
    sudo rm /tmp/hwkeys.img

Transferring Keys to the Security Device
========================================

The keys are now backed up, so it is safe to transfer your keys to the USB security key.
Transfer each key::

    gpg --edit-key $KEY_ID

    key 1
    keytocard
    key 1
    key 2
    keytocard
    key2
    key3
    keytocard
    save

Verify private keys are stubs on your keyring::

    gpg --list-secret-keys

    sec#  ed25519/0x042E55F6FA3635DD 2026-06-16 [C]
          Key fingerprint = AE9A 1DFB 1B85 41A0 1AAC  4672 042E 55F6 FA36 35DD
    uid                   [ultimate] Sean Gillespie <sean.gillespie@iohk.io>
    ssb>  ed25519/0xACF66F29D83D1300 2026-06-16 [S] [expires: 2027-06-16]
    ssb>  cv25519/0x0CF906BA2E209653 2026-06-16 [E] [expires: 2027-06-16]
    ssb>  ed25519/0xA673A642F084EB68 2026-06-16 [A] [expires: 2027-06-16]

Pay special attention to the symbols after ``sec`` and ``ssb``. A ``#`` indicates the key
has been taken offline, ``>`` indicates is stored on a smartcard.

Renewing Subkeys
================

After expiration, we will be renewing the subkeys, rather than replacing them. Renewing
subkeys is much simpler, but may be less secure. Both methods require access to the
certify key.

Insert the USB storage device and copy it to a local image::

    # Double check this command and make darned sure you aren't overwriting your backup
    # device!
    sudo dd bs=4M status=progress conv=fsync oflag=direct \
      of="/tmp/hwkeys.img" \
      if=/dev/sda1

Unlock and mount the image::

    sudo systemd-cryptsetup attach hwkeys-img /tmp/hwkeys.img
    sudo mount /dev/mapper/hwkeys-img /mnt

Create a temporary GPG home::

    export GNUPGHOME=$(mktemp --directory "/run/user/$(id -u)/gpg.XXXX")
    cp $HOME/.gnupg/gpg.conf $GNUPGHOME

Import all keys that need to be updated::

    gpg --armor --import personal/sean-gillespie-full.key # Personal identity
    gpg --armor --import work/sean-gillespie-iog-full.key # Work identity

Reset the expiration::

    gpg --edit-key $KEY_ID

    key 1
    key 2
    key 3
    expire
    1y

Changing expiration does not alter any private keys, so we only need to export the renewed
public keys::

    gpg --armor --export --output personal/sean-gillespie.asc $KEY_ID # Personal identity
    gpg --armor --export --output work/sean-gillespie-iog.asc $KEY_ID # Work identity

Commit them::

    git add \*.asc
    git commit

If you haven't already, this would be a good time to add a ``README.md``.

Unmount and write the image to USB media::

    umount /mnt
    sudo systemd-cryptsetup detach hwkeys-img

    # Double check this command and make darned sure you are writing to the correct 
    # device!
    sudo dd bs=4M status=progress conv=fsync oflag=direct \
      if="/tmp/hwkeys.img" \
      of=/dev/sda1

    # If desired, repeat on another USB storage device 
    sudo dd bs=4M status=progress conv=fsync oflag=direct \
      if="/tmp/hwkeys.img" \
      of=/dev/sdb1
