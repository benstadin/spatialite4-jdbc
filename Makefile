# use JDK1.5 to build native libraries

include Makefile.common

RESOURCE_DIR = src/main/resources

.phony: all package win32 mac32 mac64 linux32 native deploy

all: package

deploy: 
	mvn deploy 

MVN:=mvn
SRC:=src/main/java

OUT_DIR:=$(TARGET)/spatialite4-$(OS_NAME)-$(OS_ARCH)
SQLITE_ARCHIVE:=$(TARGET)/$(sqlite)-amal.zip
SQLITE_UNPACKED:=$(TARGET)/sqlite-unpack.log
SQLITE_AMAL_DIR=$(TARGET)/$(SQLITE_AMAL_PREFIX)

SPATIALITE_ARCHIVE:=$(TARGET)/libspatialite-$(SPATIALITE_VERSION).zip
SPATIALITE_UNPACKED:=$(TARGET)/spatialite-unpack.log
SPATIALITE_DIR=$(TARGET)/libspatialite-$(SPATIALITE_VERSION)
SPATIALITE_LIB=$(SPATIALITE_DIR)/src/.libs/libspatialite.a

ifeq ($(OS_NAME),Windows)
	SPATIALITE_CONFIG_FLAGS = --enable-freexl=no --enable-proj=yes --enable-geos=yes --enable-lwgeom=no
    SPATIALITE_FLAGS = 
else ifeq ($(OS_NAME),Linux)
	SPATIALITE_CONFIG_FLAGS = --enable-freexl=no --enable-proj=yes --enable-geos=yes --enable-lwgeom=no
    SPATIALITE_FLAGS = $(SPATIALITE_DIR)/src/.libs/libspatialite.a /opt/local/lib/libgeos.a /opt/local/lib/libproj.a /opt/local/lib/libgeos_c.a -lxml2  /opt/local/lib/libiconv.a -lz $(SPATIALITE_DIR)/src/virtualtext/.libs/libvirtualtext.a -lstdc++
else ifeq ($(OS_NAME),Mac)
	ifeq ($(target),Mac-x86_64)
    	SPATIALITE_CONFIG_FLAGS = --enable-freexl=no --enable-proj=yes --enable-geos=yes --enable-lwgeom=no
		SPATIALITE_FLAGS = $(SPATIALITE_DIR)/src/.libs/libspatialite.a /opt/local/lib/libgeos.a /opt/local/lib/libproj.a /opt/local/lib/libgeos_c.a -lxml2  /opt/local/lib/libiconv.a -lz $(SPATIALITE_DIR)/src/virtualtext/.libs/libvirtualtext.a -lstdc++
    else
    	SPATIALITE_CONFIG_FLAGS = --enable-freexl=no --enable-proj=yes --enable-geos=yes --enable-lwgeom=no CC=clang CXX="clang++ -std=c++11 -stdlib=libc++"
		SPATIALITE_FLAGS = $(SPATIALITE_DIR)/src/.libs/libspatialite.a /opt/local/lib/libgeos.a /opt/local/lib/libproj.a /opt/local/lib/libgeos_c.a -lxml2  /opt/local/lib/libiconv.a -lz $(SPATIALITE_DIR)/src/virtualtext/.libs/libvirtualtext.a 
    endif
endif

CFLAGS:= -I$(OUT_DIR) -I$(SQLITE_AMAL_DIR) -I$(SPATIALITE_DIR)/src/headers -I$(SPATIALITE_DIR)/src/include $(CFLAGS)

$(SQLITE_ARCHIVE):
	@mkdir -p $(@D)
	curl -o$@ http://www.sqlite.org/2014/$(SQLITE_AMAL_PREFIX).zip

$(SQLITE_UNPACKED): $(SQLITE_ARCHIVE)
	unzip -qo $< -d $(TARGET)
	touch $@
	
$(SPATIALITE_ARCHIVE):
	@mkdir -p $(@D)
	curl -o$@ http://www.gaia-gis.it/gaia-sins/libspatialite-sources/libspatialite-$(SPATIALITE_VERSION).zip
	
$(SPATIALITE_UNPACKED): $(SPATIALITE_ARCHIVE)
	unzip -qo $< -d $(TARGET)
	touch $@

$(SPATIALITE_LIB): $(SPATIALITE_UNPACKED)
	(cd $(SPATIALITE_DIR) && ./configure $(SPATIALITE_CONFIG_FLAGS))
	(cd $(SPATIALITE_DIR) && make)

$(OUT_DIR)/org/spatialite4/%.class: src/main/java/org/spatialite4/%.java
	@mkdir -p $(@D)
	$(JAVAC) -source 1.5 -target 1.5 -sourcepath $(SRC) -d $(OUT_DIR) $<

jni-header: $(OUT_DIR)/NativeDB.h

$(OUT_DIR)/NativeDB.h: $(OUT_DIR)/org/spatialite4/core/NativeDB.class
	$(JAVAH) -classpath $(OUT_DIR) -jni -o $@ org.spatialite4.core.NativeDB

test:
	mvn test

clean: clean-native clean-java clean-tests

$(OUT_DIR)/sqlite3.o : $(SQLITE_UNPACKED) $(SPATIALITE_LIB)
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

$(OUT_DIR)/$(LIBNAME): $(OUT_DIR)/sqlite3.o $(SRC)/org/spatialite4/core/NativeDB.c $(OUT_DIR)/NativeDB.h
	@mkdir -p $(@D)
	$(CC) $(CFLAGS) -c -o $(OUT_DIR)/NativeDB.o $(SRC)/org/spatialite4/core/NativeDB.c $(SPATIALITE_FLAGS) 
	$(CC) $(CFLAGS) -o $@ $(OUT_DIR)/*.o $(SPATIALITE_FLAGS) $(LINKFLAGS)
	$(STRIP) $@


NATIVE_DIR=src/main/resources/org/spatialite4/native/$(OS_NAME)/$(OS_ARCH)
NATIVE_TARGET_DIR:=$(TARGET)/classes/org/spatialite4/native/$(OS_NAME)/$(OS_ARCH)
NATIVE_DLL:=$(NATIVE_DIR)/$(LIBNAME)

native: $(SQLITE_UNPACKED) $(NATIVE_DLL)

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


sparcv9:
	$(MAKE) native OS_NAME=SunOS OS_ARCH=sparcv9


mac32:
	$(MAKE) native OS_NAME=Mac OS_ARCH=i386
	
mac64:
	$(MAKE) native OS_NAME=Mac OS_ARCH=x86_64
	

package: $(NATIVE32_DLL) native 
	rm -rf target/dependency-maven-plugin-markers
	DYLD_LIBRARY_PATH=$(SPATIAL_LIB_PATH) $(MVN) -Djava.library.path=$(SPATIAL_LIB_PATH) -P spatialite package

clean-native:
	rm -rf $(TARGET)/$(sqlite)-$(OS_NAME)*
	rm -rf $(SQLITE_AMAL_DIR)
	rm -f $(SQLITE_UNPACKED)
	rm -rf $(SPATIALITE_DIR)
	rm -f $(SPATIALITE_UNPACKED)

clean-java:
	rm -rf $(TARGET)/*classes
	rm -rf $(TARGET)/sqlite-jdbc-*jar

clean-tests:
	rm -rf $(TARGET)/{surefire*,testdb.jar*}
