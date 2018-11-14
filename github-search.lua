require("stream")
require("strutil")
require ("dataparser");
require ("process");
require ("net");
t=require ("terminal");


-- Some global vars
version=1.9
proxy=""
project_langs={}
project_count=0
matching_projects=0
description_maxlen=300
quit_lines=100
returned_lines=0
debug=false
strip_non_ascii=false


function CleanNonASCIIChars(str)
local i, c
local new=""


for i = 1, #str do
    c = string.sub(str, i, i)

		if string.byte(c) < 32 or string.byte(c) > 126
		then
			new=new..'?'
		else new=new..c
		end
end

return new
end


function LanguageInSearch(search_languages, language)
	if search_languages==nil or string.len(search_languages) ==0 then return true end

		T=strutil.TOKENIZER(search_languages,",")
		lang=T:next()
		while lang ~= nil
		do
		if string.upper(lang)==string.upper(language) then return true end
		lang=T:next()
		end

	return false
end

-- display the final list of projects per langugae
function DisplayLanguageCounts()

table.sort(project_langs)
io.write(t.format("~m"..project_count.." projects (" .. matching_projects.. " matching) : "))
for key,value in pairs(project_langs)
do
	io.write(key.." "..value..", ")
end
print(t.format("~0"))

end


function ParseReply(doc, search_languages)
local val=0 
local display_count=0
local str, name, description

P=dataparser.PARSER("json",doc)
str=P:value("total_count");
if str==nil then return -1 end

if (tonumber(str) < 1) then return(0) end
 
I=P:open("/items");
if I == nil then return -1 end

while I:next()
do
	language=I:value("language")
-- spdx_id"
	license=I:value("license/key")
	project_count=project_count + 1
	returned_lines=returned_lines+1
	if language == nil then language="none" end

	val=project_langs[language]
	if val == nil then project_langs[language]=1 
	else project_langs[language]=val+1
	end

	if LanguageInSearch(search_languages, language)
	then

		if strip_non_ascii == true
		then 
			name=CleanNonASCIIChars(I:value("name"))
			description=CleanNonASCIIChars(I:value("description"))
		else
			name=I:value("name")
			description=I:value("description")
		end

		print(t.format("~e~g" .. name .. "~0    lang: ~e~m" .. language .. "~0  license: ~e~m"..license.. "~0  watchers:" .. I:value("watchers") .. "  forks:" .. I:value("forks") .. "    " .. "~b" .. I:value("html_url") .. "~0"))
		if ((description_maxlen > 0) and (strutil.strlen(description) > description_maxlen)) then str=string.sub(description,1,description_maxlen).."..." end
		print(description)
		print()
		display_count=display_count+1
	end
end

if returned_lines >= quit_lines and display_count == 0
then
print(t.format("~e~rERROR:~0 ".. returned_lines .. " lines returned, but ~rnone~0 match request. (use -Q to overcome this check, but beware of rate limits)"))
return -1
end

return display_count
end




function BuildStringList(list, str)
	if list == nil or string.len(list) == 0
	then
			list=str
	else
			list=list..","..str
	end
return list
end



function PrintHelp()
print("github-search: copyright Colum Paget 2017")
print("contact: colums.projects@github.com")
print("usage:  lua github-search.lua [options] [search terms]")
print("")
print("   -l       <language list>  - languages to consider, a comma separated list. Prefix a language name with '!' to exclude.")
print("   -lang    <language list>  - languages to consider, a comma separated list. Prefix a language name with '!' to exclude.")
print("   -L       <language list>  - post filter results to show ONLY this language")
print("   -s       <sort key>       - sort results, descending order. Key can be 'stars', 'forks' or 'updated'.")
print("   +s       <sort key>       - sort results, ascending order. Key can be 'stars', 'forks' or 'updated'.")
print("   -stars   <number>         - minimum number of stars/watches that a result must have.")
print("   -S       <number>         - minimum number of stars/watches that a result must have.")
print("   -w       <number>         - minimum number of stars/watches that a result must have.")
print("   -watches <number>         - minimum number of stars/watches that a result must have.")
print("   -created <date>           - created since date.")
print("   -since   <date>           - updated since date.")
print("   -size    <bytes>          - repo larger than <bytes>. <bytes can have a metric suffix like 20k or 30G.")
print("   -sz      <bytes>          - repo larger than <bytes>. <bytes can have a metric suffix like 20k or 30G.")
print("   -license <key>            - search by repo license. <key> is a github-style license key.")
print("   -li      <key>            - search by repo license. <key> is a github-style license key.")
print("   -ascii                    - strip non-ascii chars (use to remove non-latin/UTF chars that screw up the terminal)")
print("   -n <number>               - minimum number of results to display. When used with -L filter, it's results displayed, not returned.")
print("   -dl <number>              - maximum number of characters to show of description, defaults to 300. This is to deal with annoying people who write novellas in their project description. Set to -dl 0 if you really want to read their magnum opus.")
print("   -Q <number>               - change guard level of number of failed results before giving up.")
print("   -d                        - debug mode, print out json reply from github.")
print("   -p       <proxy url>      - use a proxy")
print("   -proxy   <proxy url>      - use a proxy")
print("   -version  program version")
print("   -?       this help")
print("   -h       this help")
print("   -help    this help")
print("   --help   this help")
print("")
print("proxy urls can be are in the format <protocol>:<user>:<password>@<host>:<port>. all attributes but protcol and host are optional.")
print("proxy protocols can be:")
print("   ssh          pipe through ssh (ssh -w option)")
print("   sshtunnel    use ssh port forwarding, port automatically selected (ssh -L option)")
print("   socks4       socks4 protocol")
print("   socks5       socks5 protocol")
print("   https        https CONNECT proxy")
print("")
print("-L applies a post-filter on the results, as github takes the language argument as a hint, not a hard requirement. Thus with -L github can return 100 results, but if only 3 of them are in your required language, only three are displayed, unlike '-l' which will display all 100. -n can be used to insist we keep pulling pages until a certain number are displayed.")
print("However, even if '-n' is used, if more than 100 results are returned with no matches displayed, the search will return an error. You can change this limit using '-Q', but be aware that the search service is rate-limited, and pulling too many results can get you locked out ofr a time.")
print("")
print("examples:")
print("   lua github-search honeypot                    - search for things matching 'honeypot'")
print("   lua github-search ssh honeypot                - search for things matching 'ssh honeypot'")
print("   lua github-search -l c++,go ssh honeypot      - search for things matching 'ssh honeypot' and written in either c++ or go")
print("   lua github-search -n 10 -l go honeypot         - search for things matching 'honeypot' in go, until at least 10 displayed")
end




function ParseCommandLine(args)
local langs=""
local query=""
local query_langs=""
local sort=""
local num_results=0

for i,v in ipairs(args)
do
	if v == '-l' or v == '-lang'
	then
		if string.len(query_langs) > 0 then query_langs = query_langs .. "," end
		query_langs=query_langs .. args[i+1]
		args[i+1]=""
	elseif v == '-L'
	then
--			if string.len(langs) ==0 then langs=args[i+1] end
			langs=BuildStringList(langs,args[i+1])
			args[i+1]=""
	elseif v == '-s'
	then
		sort=args[i+1].."&order=desc"
		args[i+1]=""
	elseif v == '+s'
	then
		sort=args[i+1].."&order=asc"
		args[i+1]=""
	elseif v == '-S' or v == '-w' or v == '-stars' or v == '-watches'
	then
		if string.len(query) > 0 then query=query.." " end
		query=query .. "stars:>" .. args[i+1]
		args[i+1]=""
	elseif v == '-created'
	then
		if string.len(query) > 0 then query=query.." " end
		query=query .. "created:>" .. args[i+1]
		args[i+1]=""
	elseif v == '-since'
	then
		if string.len(query) > 0 then query=query.." " end
		query=query .. "pushed:>" .. args[i+1]
		args[i+1]=""
	elseif v == '-licence' or v == "-license" or v =="-li"
	then
		if string.len(query) > 0 then query=query.." " end
		query=query .. "license:" .. args[i+1]
		args[i+1]=""
	elseif v == '-size' or v == "-sz"
	then
		if string.len(query) > 0 then query=query.." " end
		query=query .. "size:>" .. args[i+1]
		args[i+1]=""
	elseif v == '-p' or v == '-proxy'
	then
		proxy=args[i+1]
		args[i+1]=""
	elseif v == '-n' 
	then
		num_results=tonumber(args[i+1])
		args[i+1]=""
	elseif v == '-Q' 
	then
		quit_lines=tonumber(args[i+1])
		args[i+1]=""
	elseif v == '-dl' 
	then
		description_maxlen=tonumber(args[i+1])
		args[i+1]=""
	elseif v == '-ascii' 
	then
		strip_non_ascii=true
	elseif v == '-?' or v == '-h' or v == '-help' or v == '--help'
	then
		PrintHelp()
		process.exit(0);
	elseif v == '-d' 
	then
		debug=true
	elseif v == '-version' or v == '--version'
	then
		print("version: "..version)
		process.exit(0);
	else
		if string.len(query) > 0 then query=query.." " end
		query=query .. v
	end
end



if string.len(query) < 1 and string.len(query_langs)  < 1
then
	print("Please supply a search term on the command line")
	process.exit(0)
end

return query,langs,query_langs,sort,num_results
end





function ConnectedOkay(S)

if S == nil then return false end

ResponseCode=S:getvalue("HTTP:ResponseCode")
if ResponseCode == "200" then return true end

return false
end



function IterateRequests(query, sort, required_results)

local val=0
local pgcount=1
local url, doc
local S

while matching_projects < required_results
do
	url="https://api.github.com/search/repositories?q=" .. query .. "&sort="..sort.."&per_page=100".."&page="..pgcount;
	 print("QUERY: "..url)

	S=stream.STREAM(url);
	if ConnectedOkay(S)
	then
		doc=S:readdoc()
		if debug == true then print(doc) end
		val=ParseReply(doc, languages)
		if val < 1 then break end
		matching_projects = matching_projects + val
	else
		print("Bad server reply, either out of results or rate-limiting");
		break;
	end
	pgcount=pgcount + 1
end
 
end



function QueryFormatLanguages(qlang, languages)
local output=""

-- if we are postfiltering by language but didn't specify any query language then set the query language to be the same as the postfilter
if string.len(languages) > 0 and string.len(qlang) == 0 then qlang=languages end
if string.len(qlang) > 0
then
	toks=strutil.TOKENIZER(qlang,",")
	item=toks:next()
	while item
	do
		if (string.sub(item, 0, 1) == '!')
		then
			output=output .. " -language:" .. string.sub(item,2);
		else
			output=output .. " language:" .. item;
		end
	item=toks:next()
	end
end

print("qlang: ",output)
return output
end

---------------------------------------- MAIN STARTS HERE --------------------------------------------

-- lu_set sets values that change libUseful's behavior, here we set the default user-agent string for this script
process.lu_set("HTTP:UserAgent","Colums Github Search Script (https://github.com/ColumPaget/github-search)")

query,languages,qlang,sort,required_results=ParseCommandLine(arg)

if string.len(proxy) then net.setProxy(proxy) end

query=query .. QueryFormatLanguages(qlang, languages)

Qquery=strutil.httpQuote(query);
if required_results < 1 then required_results=1 end

IterateRequests(Qquery, sort, required_results)
DisplayLanguageCounts()

