package owel;

import haxe.Constraints.Function;

#if js
import js.Browser;
#elseif (php)
import php.Web;
import php.Lib;
#end

class Router
{

    private var _routes:Array<String>;
    private var _routeCbs:Array<Function>;
    private var _pages:Array<String>;
    private var _currentPath:Array<String>;

    #if php
    private var _serverParam:String;
    #end

    /**
    * Creates a router for URL-matching.
    *
    * @param serverParam (Server-only) Specify the parameter name to use in URLs.
    **/
    public function new(#if php serverParam:String #end)
    {
        _routes = [];
        _routeCbs = [];
        _pages = [];

        #if php
        _serverParam = serverParam;
        #end

        #if js
        Browser.window.addEventListener('hashchange', function()
        {
            execute();
        });
        #end
    }

    /**
    * Gets the current path executed by the router.
    *
    * @param index (Optional) Specify which part of the URL you want to get, separated by slashes (/).
    **/
    public function getCurrentPath(?index:Int = -1)
    {
        if (index > -1)
        {
            return _currentPath[index];
        }
        else
        {
            var result = "";
            for (i in 0..._currentPath.length)
            {
                var p = _currentPath[i];
                if (i == _currentPath.length -1)
                    result += p;
                else
                    result += p;
            }
            return result;
        }
    }

    /**
    * Adds a route to the Router.
    *
    * @param path The URL path to assign.
    * @param func The function to call when the path is matched on execution.
    * @param page (Optional) The HTML page template to get for part of the result. 
    **/
    public function addRoute(path:String, func:Function, ?page:String = "")
    {
        _routes.push(path);
        _routeCbs.push(func);
        _pages.push(page);
    }

    /**
    * Executes the current page URL from the web browser.
    **/
    public function execute()
    {
        #if js
        var path = Browser.location.hash;
        #elseif php
        var params = Web.getParams();
        var path = "";
        if (params.exists(_serverParam))
        {
            path = params.get(_serverParam);
        }
        #end

        var _p = "";

        #if !php
        if (path == "")
            _p = "/";
        else
            _p = path.substr(1);
        #else
        _p = path;
        #end
        
        for (i in 0..._routes.length)
        {
            var route = _routes[i];
            var launchPath = "";
            var params = [];
            var match = false;

            if (_p == "/" && route == _p)
            {
                match = true;
                _routeCbs[i]();
                break;
            }

            var originValues = _p.split("/");
            var routeValues = route.split("/");

            if (originValues.length != routeValues.length)
                continue;

            for (j in 0...originValues.length)
            {
                if (originValues[j] != routeValues[j] && originValues[j].indexOf(":") != 0)
                {
                    match = false;
                    break;
                }

                if (originValues[j] == routeValues[j])
                {
                    launchPath += routeValues[j] + "/";
                    match = true;
                }
                else if (originValues[j].indexOf(":") == 0)
                {
                    params.push(originValues[j]);
                }
            }

            if (match)
            {
                if (params.length > 0)
                {
                    Reflect.callMethod(this, _routeCbs[i], params);
                }
                else
                    _routeCbs[i]();
                
                _currentPath = originValues;
                break;
            }
        }
    }

}