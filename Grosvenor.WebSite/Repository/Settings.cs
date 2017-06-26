using MySql.Data.MySqlClient;

namespace Grosvenor.WebSite.Repository
{
    public static class Settings
    {
        private static string _connection;
        public static string ConnectionString {
            get { return _connection = _connection ?? GetConnection() ; }
        }

        private static string  GetConnection()
        {
            return new MySqlConnectionStringBuilder()
            {
                Server = System.Configuration.ConfigurationManager.AppSettings["MysqlServer"],
                Port = 3306,
                UserID = "us1",
                Password = "pass13434",
                Database = "mydb"
            }.GetConnectionString(true);
        }
    }
}
