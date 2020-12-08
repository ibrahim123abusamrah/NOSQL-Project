
(: forest :)
xquery version "1.0-ml";
import module namespace admin = "http://marklogic.com/xdmp/admin" at "/MarkLogic/admin.xqy";
let $config := admin:get-configuration()
let $config := admin:forest-create(
  $config, 
  "world-leaders-01",
  xdmp:host(), 
  ())
return admin:save-configuration($config);

(: database :)
xquery version "1.0-ml";
import module namespace admin = "http://marklogic.com/xdmp/admin" at "/MarkLogic/admin.xqy";
let $config := admin:get-configuration()
let $config := admin:database-create(
  $config,
  "world-leaders",
  xdmp:database("Security"),
  xdmp:database("Schemas"))
return admin:save-configuration($config);

(: attach forest to database :)
xquery version "1.0-ml";
import module namespace admin = "http://marklogic.com/xdmp/admin" at "/MarkLogic/admin.xqy";
let $config := admin:get-configuration()
let $config := admin:database-attach-forest(
  $config,
  xdmp:database("world-leaders"), 
  xdmp:forest("world-leaders-01"))
return admin:save-configuration($config);

(: application server :)
xquery version "1.0-ml";
import module namespace admin = "http://marklogic.com/xdmp/admin" at "/MarkLogic/admin.xqy";
let $config := admin:get-configuration()
let $groupid := admin:group-get-id($config, "Default")
let $server := admin:http-server-create(
  $config, 
  $groupid,
  "8030-world-leaders", 
  "C:\mls-projects\world-leaders",
  8030,
  0,
  admin:database-get-id($config, "world-leaders"))
return admin:save-configuration($server);

(: load documents :)
xdmp:eval('for $d in xdmp:filesystem-directory("C:\mls-developer\unit02\world-leaders-source")//dir:entry
return xdmp:document-load($d//dir:pathname, 
  <options xmlns="xdmp:document-load">
    <uri>{fn:string($d//dir:filename)}</uri>
  </options>)',  (),
		  <options xmlns="xdmp:eval">
		    <database>{xdmp:database("world-leaders")}</database>
		  </options>)

