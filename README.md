SpatiaLite 4 JDBC Driver
==================

SpatiaLite 4 JDBC requires no configuration, since native DLLs are assembled into a single JAR (Java Archive) file. 

This is a fork of Xerial's current SQLite library and Justin Deoliveira's SpatiaLite driver, with added support for the latest SpatiaLite library (4.2+).
Spatialite 4.2+ has changed significantly, especially in regards to the extension loading. Therefore this updated and incompatible library for Spatialite 4.2 and upwards was created. 

This library bases on the following two upstream libraries:
Xerial: https://github.com/xerial/sqlite-jdbc
Justin Deoliveira's SpatiaLite JDBC driver: https://github.com/jdeolive/sqlite-jdbc

Changes:
- SpatiaLite API updates and changes to the SpatiaLite driver to support the latest 4.2+ version
- Simple cache manager added for SpatiaLite's new per-connection cache objects
- Removed old boilerplate resources and code
- Fixes to SQLite extensions code (merged with latest from SQLite)
- Fixes and auto-sanitization to open() and close() methods of the original xerial driver

Current versions included:
SQLite: 3.8.8.2
SpatiaLite: 4.2.1-RC1

Current status: Initial version. Builds on OS X and Linux with all tests ok. No real-world testing done yet. 

Usage
============ 

Note: Please see Xerial's documentation for common SQLite usage examples. This is just a very short introduction on how to initialize the SpatiaLite 4 JDBC driver.

For the general usage of JDBC, see [JDBC Tutorial](http://docs.oracle.com/javase/tutorial/jdbc/index.html) or [Oracle JDBC Documentation](http://www.oracle.com/technetwork/java/javase/tech/index-jsp-136101.html).

1.  Download spatialite-jdbc-(VERSION).jar from the release directory and append this jar file into your classpath. 
2.  Load the JDBC driver `org.spatialite.JDBC` from your code. (see the example below) 

* Usage Example  

**Spatialite.java**

java -classpath "demo:release/spatialite-jdbc-4.2.1-rc1.jar" Spatialite


```java
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.Properties;

public class Spatialite
{
    public static Connection getConnection(Properties prop) throws SQLException {
        return DriverManager.getConnection("jdbc:spatialite::memory:", prop);
    }
    
	public static void main(String[] args) 
	{
        Properties prop = new Properties();
        prop.setProperty("enable_shared_cache", "true");
        prop.setProperty("enable_load_extension", "true");
        prop.setProperty("enable_spatialite", "true");
        
        Connection conn = null;
        try {
            conn = getConnection(prop);
            Statement stat = conn.createStatement();
            stat.execute("SELECT InitSpatialMetaData()");
            stat.close();
            stat = conn.createStatement();
            ResultSet rs = stat.executeQuery("SELECT * FROM geometry_columns");
            stat.close();
            if (conn != null)
                conn.close();
        }
        catch (SQLException e) {
            e.printStackTrace();
        }
	}
}
```    


How to Specify Database Files
-----------------------------

Here is an example to select a file `C:\work\mydatabase.db` (in Windows)

Connection connection = DriverManager.getConnection("jdbc.spatialite:C:/work/mydatabase.db");

A UNIX (Linux, Mac OS X, etc) file `/home/leo/work/mydatabase.db`

Connection connection = DriverManager.getConnection("jdbc.spatialite:/home/leo/work/mydatabase.db");


How to Use Memory Databases
---------------------------
SpatiaLite supports on-memory database management, which does not create any database files. 
To use a memory database in your Java code, get the database connection as follows:

Connection connection = DriverManager.getConnection("jdbc.spatialite::memory:");

Supported Operating Systems
===========================

Currenty spatialite-jdbc-4.2.1-RC1 compiles on OS X 64 and Linux 64 (Ubuntu 14.04). 

The following operating systems are supported in theory, but no attempt to build has been done yet:

*   Windows XP, Vista (Windows, x86 architecture, x86_64) 
*   Mac OS X 10.9 (i386, x86_64) 
*   Linux i386 (Intel), amd64 (64-bit X86 Intel processor), Linux arm

License
-------
This program follows the Apache License version 2.0 (<http://www.apache.org/licenses/> ) That means:

It allows you to:

*   freely download and use this software, in whole or in part, for personal, company internal, or commercial purposes; 
*   use this software in packages or distributions that you create. 

It forbids you to:

*   redistribute any piece of our originated software without proper attribution; 
*   use any marks owned by us in any way that might state or imply that we xerial.org endorse your distribution; 
*   use any marks owned by us in any way that might state or imply that you created this software in question. 

It requires you to:

*   include a copy of the license in any redistribution you may make that includes this software; 
*   provide clear attribution to us, xerial.org for any distributions that include this software 

It does not require you to:

*   include the source of this software itself, or of any modifications you may have 
made to it, in any redistribution you may assemble that includes it; 
*   submit changes that you make to the software back to this software (though such feedback is encouraged). 

See License FAQ <http://www.apache.org/foundation/licence-FAQ.html> for more details.

