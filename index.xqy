xquery version "1.0-ml";
declare namespace ts="http://uwm.edu/courses";
declare namespace functx = "http://www.functx.com";
import module namespace search = "http://marklogic.com/appservices/search" at
"/MarkLogic/appservices/search/search.xqy";
declare variable $options :=
		<options xmlns="http://marklogic.com/appservices/search">
			<transform-results apply="snippet">
				<preferred-elements>
				<element ns="http://uwm.edu/courses" name="descr"/>
				</preferred-elements>
			</transform-results>


<search:operator name="sort">
		<search:state name="section">
				<search:sort-order direction="descending" type="xs:string">
					<search:element ns="http://uwm.edu/courses" name="section"/>
				</search:sort-order>
			<search:sort-order>
					<search:score/>
			</search:sort-order>
		</search:state>
</search:operator>
<constraint name="section">
    <range type="xs:string" collation="http://marklogic.com/collation/en/S1/AS/T00BB">
     <element ns="http://uwm.edu/courses" name="section"/>
     <facet-option>limit=5</facet-option>
     <facet-option>frequency-order</facet-option>
     <facet-option>descending</facet-option>
    </range>
  </constraint> 
   <constraint name="instructor">
    <range type="xs:string" collation="http://marklogic.com/collation/en/S1/AS/T00BB">
     <element ns="http://uwm.edu/courses" name="instructor"/>
     <facet-option>limit=5</facet-option>
     <facet-option>frequency-order</facet-option>
     <facet-option>descending</facet-option>
    </range>
  </constraint>
  <constraint name="days">
    <range type="xs:string" collation="http://marklogic.com/collation/en/S1/AS/T00BB">
     <element ns="http://uwm.edu/courses" name="days"/>
     <facet-option>limit=5</facet-option>
     <facet-option>frequency-order</facet-option>
     <facet-option>descending</facet-option>
    </range>
  </constraint>
   <constraint name="level">
    <range type="xs:string" collation="http://marklogic.com/collation/en/S1/AS/T00BB">
     <element ns="http://uwm.edu/courses" name="level"/>
     <facet-option>limit=5</facet-option>
     <facet-option>frequency-order</facet-option>
     <facet-option>descending</facet-option>
    </range>
  </constraint>
</options>;


declare variable $results :=
let $q := xdmp:get-request-field("q", "sort:section")
let $q := local:add-sort($q)
return
search:search($q, $options, xs:unsignedLong(xdmp:get-request-field("start","1")));




(: determines if the end-user set the sort through the drop-down or through editing the search text field or came from the advanced search form :)
declare function local:sort-controller(){
    if(xdmp:get-request-field("advanced")) 
    then 
        let $order := fn:replace(fn:substring-after(fn:tokenize(xdmp:get-request-field("q","sort:relevance")," ")[fn:contains(.,"sort")],"sort:"),"[()]","")
        return 
            if(fn:string-length($order) lt 1)
            then "relevance"
            else $order
    else if(xdmp:get-request-field("submitbtn") or not(xdmp:get-request-field("sortby")))
    then 
        let $order := fn:replace(fn:substring-after(fn:tokenize(xdmp:get-request-field("q","sort:section")," ")[fn:contains(.,"sort")],"sort:"),"[()]","")
        return 
            if(fn:string-length($order) lt 1)
            then "relevance"
            else $order
    else xdmp:get-request-field("sortby")
};


(: gets the current sort argument from the query string :)
declare function local:get-sort($q){
    fn:replace(fn:tokenize($q," ")[fn:contains(.,"sort")],"[()]","")
};

(: adds sort to the search query string :)
declare function local:add-sort($q){
    let $sortby := local:sort-controller()
    return
        if($sortby)
        then
            let $old-sort := local:get-sort($q)
            let $q :=
                if($old-sort)
                then search:remove-constraint($q,$old-sort,$options)
                else $q
            return fn:concat($q,"")
        else $q
};



declare function local:result-controller()
{
	if(xdmp:get-request-field("q"))
	then local:search-results()
	else 	if(xdmp:get-request-field("uri"))
			then local:course-detail()  
			else local:default-results()
};




declare function local:pagination($resultspag)
{
    let $start := xs:unsignedLong($resultspag/@start)
    let $length := xs:unsignedLong($resultspag/@page-length)
    let $total := xs:unsignedLong($resultspag/@total)
    let $last := xs:unsignedLong($start + $length -1)
    let $end := if ($total > $last) then $last else $total
    let $qtext := $resultspag/search:qtext[1]/text()
    let $next := if ($total > $last) then $last + 1 else ()
    let $previous := if (($start > 1) and ($start - $length > 0)) then fn:max((($start - $length),1)) else ()
    let $next-href := 
         if ($next) 
         then fn:concat("/index.xqy?q=",if ($qtext) then fn:encode-for-uri($qtext) else (),"&amp;start=",$next,"&amp;submitbtn=page")
         else ()
    let $previous-href := 
         if ($previous)
         then fn:concat("/index.xqy?q=",if ($qtext) then fn:encode-for-uri($qtext) else (),"&amp;start=",$previous,"&amp;submitbtn=page")
         else ()
    let $total-pages := fn:ceiling($total div $length)
    let $currpage := fn:ceiling($start div $length)
    let $pagemin := 
        fn:min(for $i in (1 to 4)
        where ($currpage - $i) > 0
        return $currpage - $i)
    let $rangestart := fn:max(($pagemin, 1))
    let $rangeend := fn:min(($total-pages,$rangestart))
    
    return (
        <div id="countdiv"><b>{$start}</b> to <b>{$end}</b> of {$total}</div>,
        <i></i>,
        if($rangestart eq $rangeend)
        then ()
        else
            <div id="pagenumdiv"> 
               { if ($previous) then <a href="{$previous-href}" title="View previous {$length} results"><img src="images/prevarrow.gif" class="imgbaseline"  border="0" /></a> else () }
               {
                 for $i in ($rangestart to $rangeend)
                 let $page-start := (($length * $i) + 1) - $length
                 let $page-href := concat("/index.xqy?q=",if ($qtext) then encode-for-uri($qtext) else (),"&amp;start=",$page-start,"&amp;submitbtn=page")
                 return 
                    if ($i eq $currpage) 
                    then <b>&#160;<u>{$i}</u>&#160;</b>
                    else <span class="hspace">&#160;<a href="{$page-href}">{$i}</a>&#160;</span>
                }
               { if ($next) then <a href="{$next-href}" title="View next {$length} results"><img src="images/nextarrow.gif" class="imgbaseline" border="0" /></a> else ()}
            </div>
    )
};


declare function local:search-results()
{
	
let $q :=xdmp:get-request-field("q")
let $items :=
		for $course in $results/search:result
		let $uri := fn:data($course/@uri)
		let $course-doc := fn:doc($uri)

	return <div>
	<div class="coursename">"{$course-doc//ts:title/text()}" #course {$course-doc//ts:course/text()} </div>
				<p >{fn:tokenize($course-doc//ts:descr, " ") [1 to 70]}
					 credits :- {$course-doc//ts:credits/text()}<br/>
					 level :- {$course-doc//ts:level/text()}<br/>
					 restrictions :- {fn:substring($course-doc//ts:restrictions/text(),4,50)}...
					 </p>
					<div> sections:- {$course-doc//ts:section[1]/text()}</div>
					 
						<div class="description">{local:description($course)}...
						<a href="index.xqy?uri={xdmp:url-encode($uri)}">[more]</a></div>
					
					<p>******************************************************************</p>
         </div>
return if($items)
		then (local:pagination($results), $items)
else <div>Sorry, no results for your search.<br/><br/><br/></div>		 

};

declare function local:facets()
{
    for $facet in $results/search:facet
    let $facet-count := fn:count($facet/search:facet-value)
    let $facet-name := fn:data($facet/@name)
    return
        if($facet-count > 0)
        then <div class="facet">
                <div class="purplesubheading"><img src="images/checkblank.gif"/>{$facet-name}</div>
                {
                        for $val in $facet/search:facet-value
                        let $print := if($val/text()) then $val/text() else ("Unknown")
                        let $qtext := ($results/search:qtext)
                        let $sort := local:get-sort($qtext)
                        let $this :=
                            if (fn:matches($val/@name/string(),"\W"))
                            then fn:concat('"',$val/@name/string(),'"')
                            else if ($val/@name eq "") then '""'
                            else $val/@name/string()
                        let $this := fn:concat($facet/@name,':',$this)
                        let $selected := fn:matches($qtext,$this,"i")
                        let $icon := 
                            if($selected)
                            then <img src="images/checkmark.gif"/>
                            else <img src="images/checkblank.gif"/>
                        let $link := 
                            if($selected)
                            then search:remove-constraint($qtext,$this,$options)
                            else if(fn:string-length($qtext) gt 0)
                            then fn:concat("(",$qtext,")"," AND ",$this)
                            else $this
                        let $link := if($sort and fn:not(local:get-sort($link))) then fn:concat($link," ",$sort) else $link
                        let $link := fn:encode-for-uri($link)
                        return
                            <div class="facet-value">{$icon}<a href="index.xqy?q={$link}">
                            {fn:lower-case($print)}</a> [{fn:data($val/@count)}]</div>
                }          
            </div>
         else <div>&#160;</div>
};

declare function local:description($course)
{
for $text in $course/search:snippet/search:match/node()
return if(fn:node-name($text) eq xs:QName("search:highlight"))
then <span class="highlight">{$text/text()}</span>
else $text
};

declare function functx:day-of-week( $date as xs:anyAtomicType? )  as xs:integer? 
{

  if (empty($date))
  then ()
  else xs:integer((xs:date($date) - xs:date('1901-01-06'))
          div xs:dayTimeDuration('P1D')) mod 7
 } ;
  declare function local:MTWRFSU($day_Of_week as xs:integer){
 
 
if($day_Of_week=1)
then "M"
else if($day_Of_week=2)
then "T"
else if($day_Of_week=3)
then "W"
else if($day_Of_week=4)
then "R"
else if($day_Of_week=5)
then "F"
else if($day_Of_week=6)
then "S"
else if($day_Of_week=0)
then "U"
else()
 };


declare function local:default-results()
{	let $date := current-date()
let $day_Of_week:=functx:day-of-week($date)
let $x:= cts:search(doc() , cts:element-word-query(xs:QName("ts:days") , local:MTWRFSU($day_Of_week)))
return
(:
<course_listing>
<c1>
<title>abusamrah</title>
</c1>
<c2></c2>
<c3></c3>
<c3></c3>

</course_listing>


:)

(for $course in $x/ts:course_listing	 
 order by $course/ts:section_listing[1]/ts:section  ascending
		return(
		 <div>
			
            <div class="coursename">"{$course//ts:title/text()}" #course {$course//ts:course/text()} </div>
				<p >
					 credits :- {$course//ts:credits}<br/>
					 level :- {$course//ts:level}<br/>
					 restrictions :- {local:course-detail3(xdmp:url-encode(fn:base-uri($course)))}...

					</p>
					<p>******************************************************************</p>
			</div>)
			  	
		)[1 to 10]
};

declare function local:course-detail()
{
	let $uri := xdmp:get-request-field("uri")
	let $course := fn:doc($uri) 
	return <div>
		<div class="coursenamelarge">"{$course//ts:title/text()}"</div>
		<div>course: {$course/ts:course_listing/ts:course/text()}</div>
				
		{if ($course/ts:course_listing/ts:note/text()) then <div class="detailitem">note: {$course/ts:course_listing/ts:note/text()}</div> else ()}
		{if ($course/ts:course_listing/ts:credits/text()) then <div class="detailitem">credits: {$course/ts:course_listing/ts:credits/text()}</div> else ()}
		{if ($course/ts:course_listing/ts:level/text()) then <div class="detailitem">level: {$course/ts:course_listing/ts:level/text()}</div> else ()}
		{if ($course/ts:course_listing/ts:restrictions/text()) then <div class="detailitem">restrictions: {$course/ts:course_listing/ts:restrictions/text()}</div> else ()}
		<div>section_listing:</div>
		
		{for $scetion in $course//ts:section_listing
		
		return 
		<div class="section_listing">
        <p>-----------------------------------------------</p>
				{ if($scetion/ts:section_note/text()) then <div>  section_note: {$scetion/ts:section_note/text()}</div> else () }
				<div>section: {$scetion/ts:section/text()}</div>
				<div>days: {$scetion/ts:days/text()}</div>
			<div>hours</div>
				<div class="hours">start: {$scetion/ts:hours/ts:start/text()}</div>
				<div class="hours">end: {$scetion/ts:hours/ts:end/text()}</div>
					<div>bldg_and_rm</div>
				<div class="bldg_and_rm">bldg: {$scetion/ts:bldg_and_rm/ts:bldg/text()}</div>
				<div class="bldg_and_rm">rm: {$scetion/ts:bldg_and_rm/ts:rm/text()}</div>
				<div>instructor: { $scetion/ts:instructor/text()}</div>
	{ if($scetion/ts:comments/text()) then <div>  comments: {$scetion/ts:comments/text()}</div> else () }

							
		</div> 
}
		</div>
		
};

declare function local:course-detail3($uri2)
{
	let $uri := $uri2
	let $course := fn:doc($uri) 
	return <div>
		<div class="coursenamelarge">"{$course//ts:title/text()}"</div>
		<div>course: {$course/ts:course_listing/ts:course/text()}</div>
				
		{if ($course/ts:course_listing/ts:note/text()) then <div class="detailitem">note: {$course/ts:course_listing/ts:note/text()}</div> else ()}
		{if ($course/ts:course_listing/ts:credits/text()) then <div class="detailitem">credits: {$course/ts:course_listing/ts:credits/text()}</div> else ()}
		{if ($course/ts:course_listing/ts:level/text()) then <div class="detailitem">level: {$course/ts:course_listing/ts:level/text()}</div> else ()}
		{if ($course/ts:course_listing/ts:restrictions/text()) then <div class="detailitem">restrictions: {$course/ts:course_listing/ts:restrictions/text()}</div> else ()}
		<div>section_listing:</div>
		
		{for $scetion in $course//ts:section_listing
		
		return 
		<div class="section_listing">
        <p>-----------------------------------------------</p>
				{ if($scetion/ts:section_note/text()) then <div>  section_note: {$scetion/ts:section_note/text()}</div> else () }
				<div>section: {$scetion/ts:section/text()}</div>
				<div>days: {$scetion/ts:days/text()}</div>
			<div>hours</div>
				<div class="hours">start: {$scetion/ts:hours/ts:start/text()}</div>
				<div class="hours">end: {$scetion/ts:hours/ts:end/text()}</div>
					<div>bldg_and_rm</div>
				<div class="bldg_and_rm">bldg: {$scetion/ts:bldg_and_rm/ts:bldg/text()}</div>
				<div class="bldg_and_rm">rm: {$scetion/ts:bldg_and_rm/ts:rm/text()}</div>
				<div>instructor: { $scetion/ts:instructor/text()}</div>
	{ if($scetion/ts:comments/text()) then <div>  comments: {$scetion/ts:comments/text()}</div> else () }

							
		</div> 
}
		</div>
		
};

xdmp:set-response-content-type("text/html; charset=utf-8"),
'<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">',
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title>courses</title>
<link href="css/courses.css" rel="stylesheet" type="text/css"/>
</head>
<body>
<div id="wrapper">
<div id="header"><a href="index.xqy"><img src="images/banner.jpg" width="918" height="254" border="0"/></a></div>
<div id="leftcol">
  <img src="images/checkblank.gif"/>{local:facets()}<br />
  <br />
  <div class="purplesubheading"><img src="images/checkblank.gif"/>check your birthday!</div>
  <form name="formbday" method="get" action="index.xqy" id="formbday">
    <img src="images/checkblank.gif" width="7"/>
    <input type="text" name="bday" id="bday" size="15"/> 
    <input type="submit" id="btnbday" value="go"/>
  </form>
  <div class="tinynoitalics"><img src="images/checkblank.gif"/>(e.g. 1965-10-31)</div>
</div>
<div id="rightcol">
  <form name="form1" method="get" action="index.xqy" id="form1">
  <div id="searchdiv">
<input type="text" class="form-control w-75 mx-4" name="q" id="q" size="50" value="{local:add-sort(xdmp:get-request-field("q"))}"/>
		
 <button type="button" id="reset_button" onclick="document.getElementById('bday').value = ''; document.getElementById('q').value = ''; document.location.href='index.xqy'">x</button>   <input style="border:0; width:0; height:0; background-color: #A7C030" type="text" size="0" maxlength="0"/><input type="submit" id="submitbtn" name="submitbtn" value="search"/>&#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;<a href="advanced.xqy">advanced search</a>
  </div>
  <div id="detaildiv">
  {  local:result-controller()  }  	
  </div>
  </form>
</div>
<div id="footer"></div>
</div>
</body>
</html>
