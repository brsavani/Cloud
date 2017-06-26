using System.Data.Entity;
using MySql.Data.Entity;

namespace Grosvenor.WebSite.Repository
{
    [DbConfigurationType(typeof(MySqlEFConfiguration))]
    public class MySqlContext : DbContext
    {
        public MySqlContext() : base(Settings.ConnectionString)
        {
            Database.SetInitializer<MySqlContext>(new CreateDatabaseIfNotExists<MySqlContext>());
        }

        public DbSet<HelloWorld> HelloWorld { get; set; }
    }
}
 