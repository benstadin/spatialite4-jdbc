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

