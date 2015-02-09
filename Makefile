# use JDK1.5 to build native libraries

include Makefile.common

RESOURCE_DIR = src/main/resources

.phony: all package win32 mac32 mac64 linux32 linux64 native deploy

all: package

deploy: 
	mvn deploy 

MVN:=mvn
SRC:=src/main/java

OUT_DIR:=$(TARGET)/spatialite-$(OS_NAME)-$(OS_ARCH)

ICONV_ARCHIVE:=$(TARGET)/iconv-$(ICONV_VERSION).tar.gz
ICONV_UNPACKED:=$(TARGET)/iconv-unpack.log
ICONV_DIR=$(TARGET)/libiconv-$(ICONV_VERSION)
ICONV_LIB=$(ICONV_DIR)/lib/.libs/libiconv.a

$(ICONV_ARCHIVE):
	@mkdir -p $(@D)
	curl -o $@ http://ftp.gnu.org/pub/gnu/libiconv/libiconv-$(ICONV_VERSION).tar.gz
	
$(ICONV_UNPACKED): $(ICONV_ARCHIVE)
	tar -xzf $< -C $(TARGET)
	patch -p0 -d $(ICONV_DIR) < libiconv-glibc-2.16.patch
	touch $@

$(ICONV_LIB): $(ICONV_UNPACKED)
	if [ ! -f $(ICONV_DIR)/Makefile ]; then (cd $(ICONV_DIR) && ./configure $(ICONV_CONFIG_FLAGS)); fi;	
	(cd $(ICONV_DIR) && make)

GEOS_ARCHIVE:=$(TARGET)/geos-$(GEOS_VERSION).tar.bz2
GEOS_UNPACKED:=$(TARGET)/geos-unpack.log
GEOS_DIR=$(TARGET)/geos-$(GEOS_VERSION)
GEOS_LIB=$(GEOS_DIR)/src/.libs/libgeos.a
GEOS_C_LIB=$(GEOS_DIR)/capi/.libs/libgeos_c.a

$(GEOS_ARCHIVE):
	@mkdir -p $(@D)
	curl -o $@ http://download.osgeo.org/geos/geos-$(GEOS_VERSION).tar.bz2
	
$(GEOS_UNPACKED): $(GEOS_ARCHIVE)
	tar -xjf $< -C $(TARGET)
	touch $@

$(GEOS_LIB): $(GEOS_UNPACKED)
	if [ ! -f $(GEOS_DIR)/Makefile ]; then (cd $(GEOS_DIR) && $(GEOS_FORCE_COMPILERS) ./configure $(GEOS_CONFIG_FLAGS)); fi;	
	(cd $(GEOS_DIR) && make)

PROJ_ARCHIVE:=$(TARGET)/proj-$(PROJ_VERSION).tar.gz
PROJ_UNPACKED:=$(TARGET)/proj-unpack.log
PROJ_DIR=$(TARGET)/proj-$(PROJ_VERSION)
PROJ_LIB=$(PROJ_DIR)/src/.libs/libproj.a

$(PROJ_ARCHIVE):
	@mkdir -p $(@D)
	curl -o $@ http://download.osgeo.org/proj/proj-$(PROJ_VERSION).tar.gz
	
$(PROJ_UNPACKED): $(PROJ_ARCHIVE)
	tar -xzf $< -C $(TARGET)
	touch $@

$(PROJ_LIB): $(PROJ_UNPACKED)
	if [ ! -f $(PROJ_DIR)/Makefile ]; then (cd $(PROJ_DIR) && ./configure $(PROJ_CONFIG_FLAGS)); fi;
	(cd $(PROJ_DIR) && make)

LIBXML2_ARCHIVE:=$(TARGET)/libxml2-$(LIBXML2_VERSION).tar.gz
LIBXML2_UNPACKED:=$(TARGET)/libxml2-unpack.log
LIBXML2_DIR=$(TARGET)/libxml2-$(LIBXML2_VERSION)
LIBXML2_LIB=$(LIBXML2_DIR)/src/.libs/libxml2.a

$(LIBXML2_ARCHIVE):
	@mkdir -p $(@D)
	curl -o $@ http://xmlsoft.org/sources/libxml2-$(LIBXML2_VERSION).tar.gz
	
$(LIBXML2_UNPACKED): $(LIBXML2_ARCHIVE)
	tar -xzf $< -C $(TARGET)
	touch $@

$(LIBXML2_LIB): $(LIBXML2_UNPACKED)
	if [ ! -f $(LIBXML2_DIR)/Makefile ]; then (cd $(LIBXML2_DIR) && ./configure $(LIBXML2_CONFIG_FLAGS)); fi;
	(cd $(LIBXML2_DIR) && make)

ZLIB_ARCHIVE:=$(TARGET)/zlib-$(ZLIB_VERSION).tar.gz
ZLIB_UNPACKED:=$(TARGET)/zlib-unpack.log
ZLIB_DIR=$(TARGET)/zlib-$(ZLIB_VERSION)
ZLIB_LIB=$(ZLIB_DIR)/src/.libs/libz.a

$(ZLIB_ARCHIVE):
	@mkdir -p $(@D)
	curl -o $@ http://fossies.org/linux/misc/zlib-$(ZLIB_VERSION).tar.gz
	
$(ZLIB_UNPACKED): $(ZLIB_ARCHIVE)
	tar -xzf $< -C $(TARGET)
	touch $@

$(ZLIB_LIB): $(ZLIB_UNPACKED)
	(cd $(ZLIB_DIR) && export CFLAGS='-fPIC'; export CXXFLAGS='-fPIC'; ./configure)
	(cd $(ZLIB_DIR) && make)

LZMA_ARCHIVE:=$(TARGET)/lzma-$(LZMA_VERSION).tar.gz
LZMA_UNPACKED:=$(TARGET)/lzma-unpack.log
LZMA_DIR=$(TARGET)/lzma-$(LZMA_VERSION)
LZMA_LIB=$(LZMA_DIR)/src/sdk/7zip/Compress/LZMA/libLZMA.a

$(LZMA_ARCHIVE):
	@mkdir -p $(@D)
	curl -o $@ http://tukaani.org/lzma/lzma-$(LZMA_VERSION).tar.gz
	
$(LZMA_UNPACKED): $(LZMA_ARCHIVE)
	tar -xzf $< -C $(TARGET)
	touch $@

$(LZMA_LIB): $(LZMA_UNPACKED)
	if [ ! -f $(LZMA_DIR)/Makefile ]; then (cd $(LZMA_DIR) && ./configure $(LZMA_CONFIG_FLAGS)); fi;
	(cd $(LZMA_DIR) && make)

SQLITE_ARCHIVE:=$(TARGET)/$(sqlite)-amal.zip
SQLITE_UNPACKED:=$(TARGET)/sqlite-unpack.log
SQLITE_AMAL_DIR=$(TARGET)/$(SQLITE_AMAL_PREFIX)

$(SQLITE_ARCHIVE):
	@mkdir -p $(@D)
	curl -o $@ http://www.sqlite.org/2015/$(SQLITE_AMAL_PREFIX).zip

$(SQLITE_UNPACKED): $(SQLITE_ARCHIVE)
	unzip -qo $< -d $(TARGET)
	touch $@

SPATIALITE_ARCHIVE:=$(TARGET)/libspatialite-$(SPATIALITE_VERSION).zip
SPATIALITE_UNPACKED:=$(TARGET)/spatialite-unpack.log
SPATIALITE_DIR=$(TARGET)/libspatialite-$(SPATIALITE_VERSION)
SPATIALITE_LIB=$(SPATIALITE_DIR)/src/.libs/libspatialite.a
SPATIALITE_VIRTUALTEXT_LIB=$(SPATIALITE_DIR)/src/virtualtext/.libs/libvirtualtext.a

$(SPATIALITE_ARCHIVE):
	@mkdir -p $(@D)
	curl -o$@ http://www.gaia-gis.it/gaia-sins/libspatialite-sources/libspatialite-$(SPATIALITE_VERSION).zip
	
$(SPATIALITE_UNPACKED): $(SPATIALITE_ARCHIVE)
	unzip -qo $< -d $(TARGET)
	touch $@

$(SPATIALITE_LIB): $(SPATIALITE_UNPACKED)
	if [ ! -f $(SPATIALITE_DIR)/Makefile ]; then (cd $(SPATIALITE_DIR) && ./configure $(SPATIALITE_CONFIG_FLAGS)); fi;
	(cd $(SPATIALITE_DIR) && make)

CFLAGS:= -I$(ZLIB_DIR) -I$(LZMA_DIR)/src -I$(LIBXML2_DIR)/include -I$(PROJ_DIR)/src -I$(GEOS_DIR)/include -I$(ICONV_DIR)/include -I$(OUT_DIR) -I$(SQLITE_AMAL_DIR) -I$(SPATIALITE_DIR)/src/headers -I$(SPATIALITE_DIR)/src/include $(CFLAGS)

$(OUT_DIR)/org/spatialite/%.class: src/main/java/org/spatialite/%.java
	@mkdir -p $(@D)
	$(JAVAC) -source 1.5 -target 1.5 -sourcepath $(SRC) -d $(OUT_DIR) $<

jni-header: $(OUT_DIR)/NativeDB.h

$(OUT_DIR)/NativeDB.h: $(OUT_DIR)/org/spatialite/core/NativeDB.class
	$(JAVAH) -classpath $(OUT_DIR) -jni -o $@ org.spatialite.core.NativeDB

test:
	mvn test

clean: clean-native clean-java clean-tests

$(OUT_DIR)/sqlite3.o : $(LZMA_LIB) $(ZLIB_LIB) $(LIBXML2_LIB) $(PROJ_LIB) $(GEOS_LIB) $(SQLITE_UNPACKED) $(SPATIALITE_LIB) $(ICONV_LIB)
	@mkdir -p $(@D)
	perl -p -e "s/sqlite3_api;/sqlite3_api = 0;/g" \
	    $(SQLITE_AMAL_DIR)/sqlite3ext.h > $(OUT_DIR)/sqlite3ext.h
# insert a code for loading extension functions
	perl -p -e "s/^opendb_out:/  if(!db->mallocFailed && rc==SQLITE_OK){ rc = RegisterExtensionFunctions(db); }\nopendb_out:/;" \
	    $(SQLITE_AMAL_DIR)/sqlite3.c > $(OUT_DIR)/sqlite3.c
	cat src/main/ext/*.c >> $(OUT_DIR)/sqlite3.c
	$(CC) -o $@ -c $(CFLAGS) \
	    -DSQLITE_ENABLE_LOAD_EXTENSION=1 \
	    -DSQLITE_ENABLE_UPDATE_DELETE_LIMIT \
	    -DSQLITE_ENABLE_COLUMN_METADATA \
	    -DSQLITE_CORE \
	    -DSQLITE_ENABLE_FTS3 \
	    -DSQLITE_ENABLE_FTS3_PARENTHESIS \
	    -DSQLITE_ENABLE_RTREE \
	    -DSQLITE_ENABLE_STAT2 \
	    $(SQLITE_FLAGS) \
	    $(OUT_DIR)/sqlite3.c

$(OUT_DIR)/$(LIBNAME): $(OUT_DIR)/sqlite3.o $(SRC)/org/spatialite/core/NativeDB.c $(OUT_DIR)/NativeDB.h
	@mkdir -p $(@D)
	$(CC) $(CFLAGS) -c -o $(OUT_DIR)/NativeDB.o $(SRC)/org/spatialite/core/NativeDB.c $(SPATIALITE_FLAGS) 
	$(CC) $(CFLAGS) -o $@ $(OUT_DIR)/*.o $(SPATIALITE_FLAGS) $(LINKFLAGS)
	$(STRIP) $@


NATIVE_DIR=src/main/resources/org/spatialite/native/$(OS_NAME)/$(OS_ARCH)
NATIVE_TARGET_DIR:=$(TARGET)/classes/org/spatialite/native/$(OS_NAME)/$(OS_ARCH)
NATIVE_DLL:=$(NATIVE_DIR)/$(LIBNAME)

native: $(NATIVE_DLL)

$(NATIVE_DLL): $(OUT_DIR)/$(LIBNAME)
	@mkdir -p $(@D)
	cp $< $@
	@mkdir -p $(NATIVE_TARGET_DIR)
	cp $< $(NATIVE_TARGET_DIR)/$(LIBNAME)


win32: 
	$(MAKE) native CC=i686-w64-mingw32-gcc OS_NAME=Windows OS_ARCH=x86

win64: 
	$(MAKE) native CC=x86_64-w64-mingw32-gcc OS_NAME=Windows OS_ARCH=amd64

linux32:
	$(MAKE) native OS_NAME=Linux OS_ARCH=i386


linux64:
	$(MAKE) native OS_NAME=Linux OS_ARCH=amd64


linuxarm:
	$(MAKE) native OS_NAME=Linux OS_ARCH=arm

sparcv9:
	$(MAKE) native OS_NAME=SunOS OS_ARCH=sparcv9

mac32:
	$(MAKE) native OS_NAME=Mac OS_ARCH=i386
	
mac64:
	$(MAKE) native OS_NAME=Mac OS_ARCH=x86_64
	

package: $(NATIVE_DLL) native 
	rm -rf target/dependency-maven-plugin-markers
	DYLD_LIBRARY_PATH=$(SPATIAL_LIB_PATH) $(MVN) -Djava.library.path=$(SPATIAL_LIB_PATH) -P spatialite package

clean-native:
	rm -rf $(OUT_DIR)
	rm -rf $(SQLITE_AMAL_DIR)
	rm -f $(SQLITE_UNPACKED)
	rm -rf $(SPATIALITE_DIR)
	rm -f $(SPATIALITE_UNPACKED)
	rm -rf $(GEOS_DIR)
	rm -f $(GEOS_UNPACKED)
	rm -rf $(PROJ_DIR)
	rm -f $(PROJ_UNPACKED)
	rm -rf $(LIBXML2_DIR)
	rm -f $(LIBXML2_UNPACKED)
	rm -rf $(ZLIB_DIR)
	rm -f $(ZLIB_UNPACKED)
	rm -rf $(LZMA_DIR)
	rm -f $(LZMA_UNPACKED)
	rm -rf $(ICONV_DIR)
	rm -f $(ICONV_UNPACKED)

clean-java:
	rm -rf $(TARGET)/*classes
	rm -rf $(TARGET)/spatialite-jdbc-*jar

clean-tests:
	rm -rf $(TARGET)/{surefire*,testdb.jar*}
