## System Requirements

A working installation of **Perl** and the **XML::LibXML** module is required.

## Obtaining the Latest Available Version

To obtain the latest available version of the **rng2vim** script, clone the official Git repository by typing the following at a shell prompt:

    git clone https://github.com/jhradilek/rng2vim.git 

This creates a new directory named **rng2vim** in your current working directory. To update an existing copy of the official repository to the latest available version, change to the directory with this copy and type:

    git pull

## Installing rng2vim in the System

To install **rng2vim** in your system, change to the directory with your working copy of the official Git repository and type the following at a shell prompt as **root**:

    make install

This installs the **rng2vim** executable, the **rng2vim**(1) manual page, and available documentation in the **/usr/local/** directory. To use a different installation directory, change the value of the **prefix** option on the command line; for example, to install **rng2vim** directly in the **/usr** directory, type as **root**:

    make prefix=/usr install

## Removing rng2vim from the System

To uninstall **rng2vim** from your system, change to the directory with your working copy of the official Git repository and type the following at a shell prompt as **root**:

    make uninstall

If you have previously changed the installation directory from the default **/usr/local/**, change the value of the **prefix** option on the command line; for example, to uninstall **rng2vim** from the **/usr** directory, type as **root**:

    make prefix=/usr uninstall
