# use JDK1.5 to build native libraries

include Makefile.common

RESOURCE_DIR = src/main/resources

.phony: all package win32 mac32 linux32 native deploy

all: package

deploy: 
	mvn deploy 

MVN:=mvn
SRC:=src/main/java
SQLITE_OUT:=$(TARGET)/$(sqlite)-$(OS_NAME)-$(OS_ARCH)
SQLITE_ARCHIVE:=$(TARGET)/$(sqlite)-amal.zip
SQLITE_UNPACKED:=$(TARGET)/sqlite-unpack.log
SQLITE_AMAL_DIR=$(TARGET)/$(SQLITE_AMAL_PREFIX)
#SPATIALITE_OUT:=$(TARGET)/libspatialite-$(SPATIALITE_VERSION)-$(OS_NAME)-$(OS_ARCH)
SPATIALITE_ARCHIVE:=$(TARGET)/libspatialite-$(SPATIALITE_VERSION).zip
SPATIALITE_UNPACKED:=$(TARGET)/spatialite-unpack.log
SPATIALITE_DIR=$(TARGET)/libspatialite-$(SPATIALITE_VERSION)
SPATIALITE_LIB=$(SPATIALITE_DIR)/src/.libs/libspatialite.a

SPATIALITE_STATIC_LIBS = $(SPATIALITE_DIR)/src/.libs/libspatialite.a $(SPATIALITE_DIR)/src/virtualtext/.libs/libvirtualtext.a 

CFLAGS:= -I$(SQLITE_OUT) -I$(SQLITE_AMAL_DIR) -I$(SPATIALITE_DIR)/src/headers -I$(SPATIALITE_DIR)/src/include $(CFLAGS)

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
	(cd $(SPATIALITE_DIR) && ./configure --enable-freexl=no --enable-proj=yes --enable-geos=yes --enable-lwgeom=yes)
	(cd $(SPATIALITE_DIR) && make)

$(SQLITE_OUT)/org/sqlite/%.class: src/main/java/org/sqlite/%.java
	@mkdir -p $(@D)
	$(JAVAC) -source 1.5 -target 1.5 -sourcepath $(SRC) -d $(SQLITE_OUT) $<

jni-header: $(SQLITE_OUT)/NativeDB.h

$(SQLITE_OUT)/NativeDB.h: $(SQLITE_OUT)/org/sqlite/core/NativeDB.class
	$(JAVAH) -classpath $(SQLITE_OUT) -jni -o $@ org.sqlite.core.NativeDB

test:
	mvn test

clean: clean-native clean-java clean-tests

$(SQLITE_OUT)/sqlite3.o : $(SQLITE_UNPACKED) $(SPATIALITE_LIB)
	@mkdir -p $(@D)
	@mkdir -p $(SPATIALITE_DIR)/src/include/spatialite
	cp $(SPATIALITE_DIR)/src/headers/*.h $(SPATIALITE_DIR)/src/include/spatialite
	cp $(SPATIALITE_DIR)/config.h $(SQLITE_OUT)
	perl -p -e "s/sqlite3_api;/sqlite3_api = 0;/g" \
	    $(SQLITE_AMAL_DIR)/sqlite3ext.h > $(SQLITE_OUT)/sqlite3ext.h
# insert a code for loading extension functions
	perl -p -e "s/^opendb_out:/  if(!db->mallocFailed && rc==SQLITE_OK){ rc = RegisterExtensionFunctions(db); }\nopendb_out:/;" \
	    $(SQLITE_AMAL_DIR)/sqlite3.c > $(SQLITE_OUT)/sqlite3.c
	cat src/main/ext/*.c >> $(SQLITE_OUT)/sqlite3.c
	$(CC) -o $@ $(SPATIALITE_STATIC_LIBS) -c $(CFLAGS) \
	    -DSQLITE_ENABLE_LOAD_EXTENSION=1 \
	    -DSQLITE_ENABLE_UPDATE_DELETE_LIMIT \
	    -DSQLITE_ENABLE_COLUMN_METADATA \
	    -DSQLITE_CORE \
	    -DSQLITE_ENABLE_FTS3 \
	    -DSQLITE_ENABLE_FTS3_PARENTHESIS \
	    -DSQLITE_ENABLE_RTREE \
	    -DSQLITE_ENABLE_STAT2 \
	    $(SQLITE_FLAGS) \
	    $(SQLITE_OUT)/sqlite3.c

$(SQLITE_OUT)/$(LIBNAME): $(SQLITE_OUT)/sqlite3.o $(SRC)/org/sqlite/core/NativeDB.c $(SQLITE_OUT)/NativeDB.h
	@mkdir -p $(@D)
	$(CC) $(CFLAGS) -c -o $(SQLITE_OUT)/NativeDB.o $(SRC)/org/sqlite/core/NativeDB.c
	$(CC) $(CFLAGS) -o $@ $(SQLITE_OUT)/*.o $(LINKFLAGS) 
	$(STRIP) $@


NATIVE_DIR=src/main/resources/org/sqlite/native/$(OS_NAME)/$(OS_ARCH)
NATIVE_TARGET_DIR:=$(TARGET)/classes/org/sqlite/native/$(OS_NAME)/$(OS_ARCH)
NATIVE_DLL:=$(NATIVE_DIR)/$(LIBNAME)

native: $(SQLITE_UNPACKED) $(NATIVE_DLL)

$(NATIVE_DLL): $(SQLITE_OUT)/$(LIBNAME)
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
	DYLD_LIBRARY_PATH=$(SPATIAL_LIB_PATH) $(MVN) -Djava.library.path=$(SPATIAL_LIB_PATH) package

clean-native:
	rm -rf $(TARGET)/$(sqlite)-$(OS_NAME)*

clean-java:
	rm -rf $(TARGET)/*classes
	rm -rf $(TARGET)/sqlite-jdbc-*jar

clean-tests:
	rm -rf $(TARGET)/{surefire*,testdb.jar*}
