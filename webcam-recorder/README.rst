README
======

A simple vlc command to run webcam utility. It will presently work only
custom v4l2 library.

The custom v4l2 library is available in present working directory. The
modified kernel module is available with Kernel Build-5.0 (github.com/FOSSEE/FOSSEE-netbook-kernel-source).

Steps to compile v4l2
---------------------

* tar -xzf libv4l.tgz

* cd libv4l

* make clean && make

* sudo sh v4l_lib_copy.sh

* sync && reboot


Contributed by: Manish Patel
