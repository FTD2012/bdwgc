# Primary targets:
# gc.a - builds basic library
# libgc.a - builds library for use with g++ "-fgc-keyword" extension
# c++ - adds C++ interface to library
# cords - adds cords (heavyweight strings) to library
# test - prints porting information, then builds basic version of gc.a,
#      	 and runs some tests of collector and cords.  Does not add cords or
#	 c++ interface to gc.a
# cord/de - builds dumb editor based on cords.
ABI_FLAG=
CC=cc $(ABI_FLAG)
CXX=CC $(ABI_FLAG)
AS=as $(ABI_FLAG)
#  The above doesn't work with gas, which doesn't run cpp.
#  Define AS as `gcc -c -x assembler-with-cpp' instead.
#  Under Irix 6, you will have to specify the ABI (-o32, -n32, or -64)
#  if you use something other than the default ABI on your machine.

CFLAGS= -O -DATOMIC_UNCOLLECTABLE -DNO_SIGNALS -DNO_EXECUTE_PERMISSION -DALL_INTERIOR_POINTERS -DSILENT

# For dynamic library builds, it may be necessary to add flags to generate
# PIC code, e.g. -fPIC on Linux.

# Setjmp_test may yield overly optimistic results when compiled
# without optimization.
# -DSILENT disables statistics printing, and improves performance.
# -DCHECKSUMS reports on erroneously clear dirty bits, and unexpectedly
#   altered stubborn objects, at substantial performance cost.
#   Use only for incremental collector debugging.
# -DFIND_LEAK causes the collector to assume that all inaccessible
#   objects should have been explicitly deallocated, and reports exceptions.
#   Finalization and the test program are not usable in this mode.
# -DSOLARIS_THREADS enables support for Solaris (thr_) threads.
#   (Clients should also define SOLARIS_THREADS and then include
#   gc.h before performing thr_ or dl* or GC_ operations.)
#   Must also define -D_REENTRANT.
# -D_SOLARIS_PTHREADS enables support for Solaris pthreads.
#   Define SOLARIS_THREADS as well.
# -DIRIX_THREADS enables support for Irix pthreads.  See README.irix.
# -DLINUX_THREADS enables support for Xavier Leroy's Linux threads.
#   see README.linux.  -D_REENTRANT may also be required.
# -DALL_INTERIOR_POINTERS allows all pointers to the interior
#   of objects to be recognized.  (See gc_priv.h for consequences.)
# -DSMALL_CONFIG tries to tune the collector for small heap sizes,
#   usually causing it to use less space in such situations.
#   Incremental collection no longer works in this case.
# -DLARGE_CONFIG tunes the collector for unusually large heaps.
#   Necessary for heaps larger than about 500 MB on most machines.
#   Recommended for heaps larger than about 64 MB.
# -DDONT_ADD_BYTE_AT_END is meaningful only with
#   -DALL_INTERIOR_POINTERS.  Normally -DALL_INTERIOR_POINTERS
#   causes all objects to be padded so that pointers just past the end of
#   an object can be recognized.  This can be expensive.  (The padding
#   is normally more than one byte due to alignment constraints.)
#   -DDONT_ADD_BYTE_AT_END disables the padding.
# -DNO_SIGNALS does not disable signals during critical parts of
#   the GC process.  This is no less correct than many malloc 
#   implementations, and it sometimes has a significant performance
#   impact.  However, it is dangerous for many not-quite-ANSI C
#   programs that call things like printf in asynchronous signal handlers.
# -DNO_EXECUTE_PERMISSION may cause some or all of the heap to not
#   have execute permission, i.e. it may be impossible to execute
#   code from the heap.  Currently this only affects the incremental
#   collector on UNIX machines.  It may greatly improve its performance,
#   since this may avoid some expensive cache synchronization.
# -DOPERATOR_NEW_ARRAY declares that the C++ compiler supports the
#   new syntax "operator new[]" for allocating and deleting arrays.
#   See gc_cpp.h for details.  No effect on the C part of the collector.
#   This is defined implicitly in a few environments.
# -DREDIRECT_MALLOC=X causes malloc, realloc, and free to be defined
#   as aliases for X, GC_realloc, and GC_free, respectively.
#   Calloc is redefined in terms of the new malloc.  X should
#   be either GC_malloc or GC_malloc_uncollectable.
#   The former is occasionally useful for working around leaks in code
#   you don't want to (or can't) look at.  It may not work for
#   existing code, but it often does.  Neither works on all platforms,
#   since some ports use malloc or calloc to obtain system memory.
#   (Probably works for UNIX, and win32.)
# -DIGNORE_FREE turns calls to free into a noop.  Only useful with
#   -DREDIRECT_MALLOC.
# -DNO_DEBUGGING removes GC_dump and the debugging routines it calls.
#   Reduces code size slightly at the expense of debuggability.
# -DJAVA_FINALIZATION makes it somewhat safer to finalize objects out of
#   order by specifying a nonstandard finalization mark procedure  (see
#   finalize.c).  Objects reachable from finalizable objects will be marked
#   in a sepearte postpass, and hence their memory won't be reclaimed.
#   Not recommended unless you are implementing a language that specifies
#   these semantics.
# -DFINALIZE_ON_DEMAND causes finalizers to be run only in response
#   to explicit GC_invoke_finalizers() calls.
# -DATOMIC_UNCOLLECTABLE includes code for GC_malloc_atomic_uncollectable.
#   This is useful if either the vendor malloc implementation is poor,
#   or if REDIRECT_MALLOC is used.
# -DHBLKSIZE=ddd, where ddd is a power of 2 between 512 and 16384, explicitly
#   sets the heap block size.  Each heap block is devoted to a single size and
#   kind of object.  For the incremental collector it makes sense to match
#   the most likely page size.  Otherwise large values result in more
#   fragmentation, but generally better performance for large heaps.
# -DUSE_MMAP use MMAP instead of sbrk to get new memory.
#   Works for Solaris and Irix.
# -DUSE_MUNMAP causes memory to be returned to the OS under the right
#   circumstances.  This currently disables VM-based incremental collection.
#   This is currently experimental, and works only under some Unix and
#   Linux versions.
# -DMMAP_STACKS (for Solaris threads) Use mmap from /dev/zero rather than
#   GC_scratch_alloc() to get stack memory.
# -DPRINT_BLACK_LIST Whenever a black list entry is added, i.e. whenever
#   the garbage collector detects a value that looks almost, but not quite,
#   like a pointer, print both the address containing the value, and the
#   value of the near-bogus-pointer.  Can be used to identifiy regions of
#   memory that are likely to contribute misidentified pointers.
# -DOLD_BLOCK_ALLOC Use the old, possibly faster, large block
#   allocation strategy.  The new strategy tries harder to minimize
#   fragmentation, sometimes at the expense of spending more time in the
#   large block allocator and/or collecting more frequently.
#   If you expect the allocator to promtly use an explicitly expanded
#   heap, this is highly recommended.
# -DGC_ASSERTIONS Enable some internal GC assertion checking.  Currently
#   this facility is only used in a few places.  It is intended primarily
#   for debugging of the garbage collector itself, but could also
#   occasionally be useful for debugging of client code.  Slows down the
#   collector somewhat, but not drastically.
#



LIBGC_CFLAGS= -O -DNO_SIGNALS -DSILENT \
    -DREDIRECT_MALLOC=GC_malloc_uncollectable \
    -DDONT_ADD_BYTE_AT_END -DALL_INTERIOR_POINTERS
#   Flags for building libgc.a -- the last two are required.

CXXFLAGS= $(CFLAGS) 
AR= ar
RANLIB= ranlib


# Redefining srcdir allows object code for the nonPCR version of the collector
# to be generated in different directories.  In this case, the destination directory
# should contain a copy of the original include directory.
srcdir = .
VPATH = $(srcdir)

OBJS= alloc.o reclaim.o allchblk.o misc.o mach_dep.o os_dep.o mark_rts.o headers.o mark.o obj_map.o blacklst.o finalize.o new_hblk.o dbg_mlc.o malloc.o stubborn.o checksums.o solaris_threads.o irix_threads.o linux_threads.o typd_mlc.o ptr_chck.o mallocx.o solaris_pthreads.o

CSRCS= reclaim.c allchblk.c misc.c alloc.c mach_dep.c os_dep.c mark_rts.c headers.c mark.c obj_map.c pcr_interface.c blacklst.c finalize.c new_hblk.c real_malloc.c dyn_load.c dbg_mlc.c malloc.c stubborn.c checksums.c solaris_threads.c irix_threads.c linux_threads.c typd_mlc.c ptr_chck.c mallocx.c solaris_pthreads.c

CORD_SRCS=  cord/cordbscs.c cord/cordxtra.c cord/cordprnt.c cord/de.c cord/cordtest.c cord/cord.h cord/ec.h cord/private/cord_pos.h cord/de_win.c cord/de_win.h cord/de_cmds.h cord/de_win.ICO cord/de_win.RC cord/SCOPTIONS.amiga cord/SMakefile.amiga

CORD_OBJS=  cord/cordbscs.o cord/cordxtra.o cord/cordprnt.o

SRCS= $(CSRCS) mips_sgi_mach_dep.s rs6000_mach_dep.s alpha_mach_dep.s \
    sparc_mach_dep.s gc.h gc_typed.h gc_hdrs.h gc_priv.h gc_private.h \
    gcconfig.h gc_mark.h include/gc_inl.h include/gc_inline.h gc.man \
    threadlibs.c if_mach.c if_not_there.c gc_cpp.cc gc_cpp.h weakpointer.h \
    gcc_support.c mips_ultrix_mach_dep.s include/gc_alloc.h gc_alloc.h \
    include/new_gc_alloc.h include/javaxfc.h sparc_sunos4_mach_dep.s \
    solaris_threads.h $(CORD_SRCS)

OTHER_FILES= Makefile PCR-Makefile OS2_MAKEFILE NT_MAKEFILE BCC_MAKEFILE \
           README test.c test_cpp.cc setjmp_t.c SMakefile.amiga \
           SCoptions.amiga README.amiga README.win32 cord/README \
           cord/gc.h include/gc.h include/gc_typed.h include/cord.h \
           include/ec.h include/private/cord_pos.h include/private/gcconfig.h \
           include/private/gc_hdrs.h include/private/gc_priv.h \
	   include/gc_cpp.h README.rs6000 \
           include/weakpointer.h README.QUICK callprocs pc_excludes \
           barrett_diagram README.OS2 README.Mac MacProjects.sit.hqx \
           MacOS.c EMX_MAKEFILE makefile.depend README.debugging \
           include/gc_cpp.h Mac_files/datastart.c Mac_files/dataend.c \
           Mac_files/MacOS_config.h Mac_files/MacOS_Test_config.h \
           add_gc_prefix.c README.solaris2 README.sgi README.hp README.uts \
	   win32_threads.c NT_THREADS_MAKEFILE gc.mak README.dj Makefile.dj \
	   README.alpha README.linux version.h Makefile.DLLs \
	   WCC_MAKEFILE

CORD_INCLUDE_FILES= $(srcdir)/gc.h $(srcdir)/cord/cord.h $(srcdir)/cord/ec.h \
           $(srcdir)/cord/private/cord_pos.h

UTILS= if_mach if_not_there threadlibs

# Libraries needed for curses applications.  Only needed for de.
CURSES= -lcurses -ltermlib

# The following is irrelevant on most systems.  But a few
# versions of make otherwise fork the shell specified in
# the SHELL environment variable.
SHELL= /bin/sh

SPECIALCFLAGS = 
# Alternative flags to the C compiler for mach_dep.c.
# Mach_dep.c often doesn't like optimization, and it's
# not time-critical anyway.
# Set SPECIALCFLAGS to -q nodirect_code on Encore.

all: gc.a gctest

pcr: PCR-Makefile gc_private.h gc_hdrs.h gc.h gcconfig.h mach_dep.o $(SRCS)
	make -f PCR-Makefile depend
	make -f PCR-Makefile

$(OBJS) test.o dyn_load.o dyn_load_sunos53.o: $(srcdir)/gc_priv.h $(srcdir)/gc_hdrs.h $(srcdir)/gc.h \
    $(srcdir)/gcconfig.h $(srcdir)/gc_typed.h Makefile
# The dependency on Makefile is needed.  Changing
# options such as -DSILENT affects the size of GC_arrays,
# invalidating all .o files that rely on gc_priv.h

mark.o typd_mlc.o finalize.o: $(srcdir)/gc_mark.h

base_lib gc.a: $(OBJS) dyn_load.o $(UTILS)
	echo > base_lib
	rm -f dont_ar_1
	./if_mach SPARC SUNOS5 touch dont_ar_1
	./if_mach SPARC SUNOS5 $(AR) rus gc.a $(OBJS) dyn_load.o
	./if_mach M68K AMIGA touch dont_ar_1
	./if_mach M68K AMIGA $(AR) -vrus gc.a $(OBJS) dyn_load.o
	./if_not_there dont_ar_1 $(AR) ru gc.a $(OBJS) dyn_load.o
	./if_not_there dont_ar_1 $(RANLIB) gc.a || cat /dev/null
#	ignore ranlib failure; that usually means it doesn't exist, and isn't needed

cords: $(CORD_OBJS) cord/cordtest $(UTILS)
	rm -f dont_ar_3
	./if_mach SPARC SUNOS5 touch dont_ar_3
	./if_mach SPARC SUNOS5 $(AR) rus gc.a $(CORD_OBJS)
	./if_mach M68K AMIGA touch dont_ar_3
	./if_mach M68K AMIGA $(AR) -vrus gc.a $(CORD_OBJS)
	./if_not_there dont_ar_3 $(AR) ru gc.a $(CORD_OBJS)
	./if_not_there dont_ar_3 $(RANLIB) gc.a || cat /dev/null

gc_cpp.o: $(srcdir)/gc_cpp.cc $(srcdir)/gc_cpp.h $(srcdir)/gc.h Makefile
	$(CXX) -c $(CXXFLAGS) $(srcdir)/gc_cpp.cc

test_cpp: $(srcdir)/test_cpp.cc $(srcdir)/gc_cpp.h gc_cpp.o $(srcdir)/gc.h \
base_lib $(UTILS)
	rm -f test_cpp
	./if_mach HP_PA "" $(CXX) $(CXXFLAGS) -o test_cpp $(srcdir)/test_cpp.cc gc_cpp.o gc.a -ldld
	./if_not_there test_cpp $(CXX) $(CXXFLAGS) -o test_cpp $(srcdir)/test_cpp.cc gc_cpp.o gc.a `./threadlibs`

c++: gc_cpp.o $(srcdir)/gc_cpp.h test_cpp
	rm -f dont_ar_4
	./if_mach SPARC SUNOS5 touch dont_ar_4
	./if_mach SPARC SUNOS5 $(AR) rus gc.a gc_cpp.o
	./if_mach M68K AMIGA touch dont_ar_4
	./if_mach M68K AMIGA $(AR) -vrus gc.a gc_cpp.o
	./if_not_there dont_ar_4 $(AR) ru gc.a gc_cpp.o
	./if_not_there dont_ar_4 $(RANLIB) gc.a || cat /dev/null
	./test_cpp 1
	echo > c++

dyn_load_sunos53.o: dyn_load.c
	$(CC) $(CFLAGS) -DSUNOS53_SHARED_LIB -c $(srcdir)/dyn_load.c -o $@

# SunOS5 shared library version of the collector
sunos5gc.so: $(OBJS) dyn_load_sunos53.o
	$(CC) -G -o sunos5gc.so $(OBJS) dyn_load_sunos53.o -ldl
	ln sunos5gc.so libgc.so

# Alpha/OSF shared library version of the collector
libalphagc.so: $(OBJS)
	ld -shared -o libalphagc.so $(OBJS) dyn_load.o -lc
	ln libalphagc.so libgc.so

# IRIX shared library version of the collector
libirixgc.so: $(OBJS) dyn_load.o
	ld -shared $(ABI_FLAG) -o libirixgc.so $(OBJS) dyn_load.o -lc
	ln libirixgc.so libgc.so

# Linux shared library version of the collector
liblinuxgc.so: $(OBJS) dyn_load.o
	gcc -shared -o liblinuxgc.so $(OBJS) dyn_load.o -lo
	ln liblinuxgc.so libgc.so

# Alternative Linux rule.  This is preferable, but is likely to break the
# Makefile for some non-linux platforms.
# LIBOBJS= $(patsubst %.o, %.lo, $(OBJS))
#
#.SUFFIXES: .lo $(SUFFIXES)
#
#.c.lo:
#	$(CC) $(CFLAGS) $(CPPFLAGS) -fPIC -c $< -o $@
#
# liblinuxgc.so: $(LIBOBJS) dyn_load.lo
# 	gcc -shared -Wl,-soname=libgc.so.0 -o libgc.so.0 $(LIBOBJS) dyn_load.lo
#	touch liblinuxgc.so

mach_dep.o: $(srcdir)/mach_dep.c $(srcdir)/mips_sgi_mach_dep.s $(srcdir)/mips_ultrix_mach_dep.s $(srcdir)/rs6000_mach_dep.s $(UTILS)
	rm -f mach_dep.o
	./if_mach MIPS IRIX5 $(AS) -o mach_dep.o $(srcdir)/mips_sgi_mach_dep.s
	./if_mach MIPS RISCOS $(AS) -o mach_dep.o $(srcdir)/mips_ultrix_mach_dep.s
	./if_mach MIPS ULTRIX $(AS) -o mach_dep.o $(srcdir)/mips_ultrix_mach_dep.s
	./if_mach RS6000 "" $(AS) -o mach_dep.o $(srcdir)/rs6000_mach_dep.s
	./if_mach ALPHA "" $(AS) -o mach_dep.o $(srcdir)/alpha_mach_dep.s
	./if_mach SPARC SUNOS5 $(AS) -o mach_dep.o $(srcdir)/sparc_mach_dep.s
	./if_mach SPARC SUNOS4 $(AS) -o mach_dep.o $(srcdir)/sparc_sunos4_mach_dep.s
	./if_mach SPARC OPENBSD $(AS) -o mach_dep.o $(srcdir)/sparc_sunos4_mach_dep.s
	./if_not_there mach_dep.o $(CC) -c $(SPECIALCFLAGS) $(srcdir)/mach_dep.c

mark_rts.o: $(srcdir)/mark_rts.c if_mach if_not_there $(UTILS)
	rm -f mark_rts.o
	-./if_mach ALPHA OSF1 $(CC) -c $(CFLAGS) -Wo,-notail $(srcdir)/mark_rts.c
	./if_not_there mark_rts.o $(CC) -c $(CFLAGS) $(srcdir)/mark_rts.c
#	Work-around for DEC optimizer tail recursion elimination bug.
#  The ALPHA-specific line should be removed if gcc is used.

alloc.o: version.h

cord/cordbscs.o: $(srcdir)/cord/cordbscs.c $(CORD_INCLUDE_FILES)
	$(CC) $(CFLAGS) -c -I$(srcdir) $(srcdir)/cord/cordbscs.c
	mv cordbscs.o cord/cordbscs.o
#  not all compilers understand -o filename

cord/cordxtra.o: $(srcdir)/cord/cordxtra.c $(CORD_INCLUDE_FILES)
	$(CC) $(CFLAGS) -c -I$(srcdir) $(srcdir)/cord/cordxtra.c
	mv cordxtra.o cord/cordxtra.o

cord/cordprnt.o: $(srcdir)/cord/cordprnt.c $(CORD_INCLUDE_FILES)
	$(CC) $(CFLAGS) -c -I$(srcdir) $(srcdir)/cord/cordprnt.c
	mv cordprnt.o cord/cordprnt.o

cord/cordtest: $(srcdir)/cord/cordtest.c $(CORD_OBJS) gc.a $(UTILS)
	rm -f cord/cordtest
	./if_mach SPARC DRSNX $(CC) $(CFLAGS) -o cord/cordtest $(srcdir)/cord/cordtest.c $(CORD_OBJS) gc.a -lucb
	./if_mach HP_PA "" $(CC) $(CFLAGS) -o cord/cordtest $(srcdir)/cord/cordtest.c $(CORD_OBJS) gc.a -ldld
	./if_not_there cord/cordtest $(CC) $(CFLAGS) -o cord/cordtest $(srcdir)/cord/cordtest.c $(CORD_OBJS) gc.a `./threadlibs`

cord/de: $(srcdir)/cord/de.c cord/cordbscs.o cord/cordxtra.o gc.a $(UTILS)
	rm -f cord/de
	./if_mach SPARC DRSNX $(CC) $(CFLAGS) -o cord/de $(srcdir)/cord/de.c cord/cordbscs.o cord/cordxtra.o gc.a $(CURSES) -lucb `./threadlibs`
	./if_mach HP_PA "" $(CC) $(CFLAGS) -o cord/de $(srcdir)/cord/de.c cord/cordbscs.o cord/cordxtra.o gc.a $(CURSES) -ldld
	./if_mach RS6000 "" $(CC) $(CFLAGS) -o cord/de $(srcdir)/cord/de.c cord/cordbscs.o cord/cordxtra.o gc.a -lcurses
	./if_mach I386 LINUX $(CC) $(CFLAGS) -o cord/de $(srcdir)/cord/de.c cord/cordbscs.o cord/cordxtra.o gc.a -lcurses `./threadlibs`
	./if_mach ALPHA LINUX $(CC) $(CFLAGS) -o cord/de $(srcdir)/cord/de.c cord/cordbscs.o cord/cordxtra.o gc.a -lcurses
	./if_mach M68K AMIGA $(CC) $(CFLAGS) -o cord/de $(srcdir)/cord/de.c cord/cordbscs.o cord/cordxtra.o gc.a -lcurses
	./if_not_there cord/de $(CC) $(CFLAGS) -o cord/de $(srcdir)/cord/de.c cord/cordbscs.o cord/cordxtra.o gc.a $(CURSES) `./threadlibs`

if_mach: $(srcdir)/if_mach.c $(srcdir)/gcconfig.h
	$(CC) $(CFLAGS) -o if_mach $(srcdir)/if_mach.c

threadlibs: $(srcdir)/threadlibs.c $(srcdir)/gcconfig.h Makefile
	$(CC) $(CFLAGS) -o threadlibs $(srcdir)/threadlibs.c

if_not_there: $(srcdir)/if_not_there.c
	$(CC) $(CFLAGS) -o if_not_there $(srcdir)/if_not_there.c

clean: 
	rm -f gc.a *.o gctest gctest_dyn_link test_cpp \
	      setjmp_test  mon.out gmon.out a.out core if_not_there if_mach \
	      threadlibs $(CORD_OBJS) cord/cordtest cord/de
	-rm -f *~

gctest: test.o gc.a if_mach if_not_there
	rm -f gctest
	./if_mach SPARC DRSNX $(CC) $(CFLAGS) -o gctest  test.o gc.a -lucb
	./if_mach HP_PA "" $(CC) $(CFLAGS) -o gctest  test.o gc.a -ldld
	./if_not_there gctest $(CC) $(CFLAGS) -o gctest test.o gc.a `./threadlibs`

# If an optimized setjmp_test generates a segmentation fault,
# odds are your compiler is broken.  Gctest may still work.
# Try compiling setjmp_t.c unoptimized.
setjmp_test: $(srcdir)/setjmp_t.c $(srcdir)/gc.h if_mach if_not_there
	$(CC) $(CFLAGS) -o setjmp_test $(srcdir)/setjmp_t.c

test:  KandRtest cord/cordtest
	cord/cordtest

# Those tests that work even with a K&R C compiler:
KandRtest: setjmp_test gctest
	./setjmp_test
	./gctest

add_gc_prefix: add_gc_prefix.c
	$(CC) -o add_gc_prefix $(srcdir)/add_gc_prefix.c

gc.tar: $(SRCS) $(OTHER_FILES) add_gc_prefix
	./add_gc_prefix $(SRCS) $(OTHER_FILES) > /tmp/gc.tar-files
	(cd $(srcdir)/.. ; tar cvfh - `cat /tmp/gc.tar-files`) > gc.tar

pc_gc.tar: $(SRCS) $(OTHER_FILES)
	tar cvfX pc_gc.tar pc_excludes $(SRCS) $(OTHER_FILES)

floppy: pc_gc.tar
	-mmd a:/cord
	-mmd a:/cord/private
	-mmd a:/include
	-mmd a:/include/private
	mkdir /tmp/pc_gc
	cat pc_gc.tar | (cd /tmp/pc_gc; tar xvf -)
	-mcopy -tmn /tmp/pc_gc/* a:
	-mcopy -tmn /tmp/pc_gc/cord/* a:/cord
	-mcopy -mn /tmp/pc_gc/cord/de_win.ICO a:/cord
	-mcopy -tmn /tmp/pc_gc/cord/private/* a:/cord/private
	-mcopy -tmn /tmp/pc_gc/include/* a:/include
	-mcopy -tmn /tmp/pc_gc/include/private/* a:/include/private
	rm -r /tmp/pc_gc

gc.tar.Z: gc.tar
	compress gc.tar

gc.tar.gz: gc.tar
	gzip gc.tar

lint: $(CSRCS) test.c
	lint -DLINT $(CSRCS) test.c | egrep -v "possible pointer alignment problem|abort|exit|sbrk|mprotect|syscall|change in ANSI|improper alignment"

# BTL: added to test shared library version of collector.
# Currently works only under SunOS5.  Requires GC_INIT call from statically
# loaded client code.
ABSDIR = `pwd`
gctest_dyn_link: test.o libgc.so
	$(CC) -L$(ABSDIR) -R$(ABSDIR) -o gctest_dyn_link test.o -lgc -ldl -lthread

gctest_irix_dyn_link: test.o libirixgc.so
	$(CC) -L$(ABSDIR) -o gctest_irix_dyn_link test.o -lirixgc

test_dll.o: test.c libgc_globals.h
	$(CC) $(CFLAGS) -DGC_USE_DLL -c test.c -o test_dll.o

test_dll: test_dll.o libgc_dll.a libgc.dll
	$(CC) test_dll.o -L$(ABSDIR) -lgc_dll -o test_dll

SYM_PREFIX-libgc=GC

# Uncomment the following line to build a GNU win32 DLL
# include Makefile.DLLs

reserved_namespace: $(SRCS)
	for file in $(SRCS) test.c test_cpp.cc; do \
		sed s/GC_/_GC_/g < $$file > tmp; \
		cp tmp $$file; \
		done

user_namespace: $(SRCS)
	for file in $(SRCS) test.c test_cpp.cc; do \
		sed s/_GC_/GC_/g < $$file > tmp; \
		cp tmp $$file; \
		done
