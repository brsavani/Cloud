using System.Collections.Generic;

namespace Grosvenor.WebSite.Repository
{
    public class MySqlInitializer : System.Data.Entity.DropCreateDatabaseIfModelChanges<MySqlContext>
    {
        protected override void Seed(MySqlContext context)
        {
            var students = new List<HelloWorld>
            {
                new HelloWorld
                {
                    Id = 1,
                    Description = "First Data",
                }
            };

            students.ForEach(s => context.HelloWorld.Add(s));
            context.SaveChanges();
        }
    }
}
