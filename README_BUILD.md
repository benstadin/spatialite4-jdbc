How to compile a new version of SQLiteJDBC
===========================================
Prerequisites
-------------
1. JDK 1.6
2. Perl
3. Maven
4. make
5. gcc (clang on OS X)
6. curl
7. unzip

Build
----- 
1. Edit the `VERSION` file and set the SQLite version to use.
2. Edit the version number in `pom.xml` to match `VERSION`.
3. Then, run:

        $ make

How to build Win64 native library
=================================
* Install cygwin with make, curl, unzip, and mingw64-x86_64-gcc-core
* (You can install MinGW64 <http://sourceforge.net/projects/mingw-w64/files/>) 

* After the installation, make sure your PATH environment variable
points to `/usr/bin` before `/bin`.

Here is the excerpt from <http://mingw-w64.sourceforge.net/>

        The mingw-w64 toolchain has been officially added to Cygwin mirrors,
        you can find the basic C toolchain as mingw64-x86_64-gcc-core. The
        languages enabled are C, Ada, C++, Fortran, Object C and Objective
        C++. There is a known caveat where calling the compiler directly as
        "/bin/x86_64-w64-mingw32-gcc" will fail, use
        "/usr/bin/x86_64-w64-mingw32-gcc" instead and make sure that your PATH
        variable has "/usr/bin" before "/bin".

* Instead, you can explicitly set the compiler:
        $ make native Windows-amd64_CC=/usr/bin/x86_64-w64-mingw32-gcc

* Then, do 
        $ make native
