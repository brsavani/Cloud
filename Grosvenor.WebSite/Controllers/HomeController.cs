using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Grosvenor.WebSite.Repository;

namespace Grosvenor.WebSite.Controllers
{
    public class HomeController : Controller
    {
        // GET: Home
        public ActionResult Index()
        {
            var databaseTextRead = string.Empty;

            try
            {
                using (var context = new MySqlContext())
                {
                    var items = context.HelloWorld.ToList();
                    foreach (var item in items)
                    {
                        databaseTextRead += (item.Id + " " + item.Description + Environment.NewLine);
                    }
                }
                ViewBag.Reponse = "Connected: DataBase Read Data => " + databaseTextRead;
            }
            catch (Exception e)
            {
                ViewBag.Reponse = "Error Connecting DataBase => " + e.Message;
            }

            return View();
        }
    }
}