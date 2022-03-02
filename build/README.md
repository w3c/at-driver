# build

This directory contains the code necessary to build a Windows 10 image for
VirtualBox.

## Instructions

Prerequisites:

- a GNU/Linux or macOS computer
- a valid Windows 10 product key
- an installation disc image for Windows 10 Professional, saved to a file named
  `Win10_21H2_English_x64.iso` ([this may be downloaded free-of-charge from
  Microsoft](https://www.microsoft.com/en-us/software-download/windows10ISO))

Procedure:

1. Install the following free and open source software:
  - [HashiCorp Packer](https://www.packer.io/) (tested with **version 1.7.10**;
    later versions may be compatible)
  - [Oracle VirtualBox](https://www.virtualbox.org/) (tested with **version
    6.1.32**; later versions may be compatible)
2. Run the following command in a terminal located in the directory containing
   this document, replacing the text XXXX with a valid Windows 10 product key:

       $ ./build.sh XXXX
