package org.spatialite4;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.Properties;

import org.junit.BeforeClass;
import org.junit.Test;

public class SpatiaLiteTest {
    
    public Connection getConnection(Properties prop) throws SQLException {
        return DriverManager.getConnection("jdbc:spatialite4::memory:", prop);
    }

    @Test
    public void spatiaLiteTest() throws Exception {
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
            try {
                ResultSet rs = stat.executeQuery("SELECT * FROM geometry_columns");
            }
            catch (SQLException e) {
                e.printStackTrace();
            }
            stat.close();
        }
        finally {
            if (conn != null)
                conn.close();
        }
    }
}
