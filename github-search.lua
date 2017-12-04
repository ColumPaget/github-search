require("stream")
require("strutil")
require ("dataparser");
require ("process");
require ("net");
t=require ("terminal");


-- Some global vars
proxy=""



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




function ParseReply(doc, search_languages)
local langs={}
local val=0 
local items=0

P=dataparser.PARSER("json",doc)
--print(t.format("%rMATCHES: " .. P:value("total_count") .. "~0"))
I=P:open("/items");
while I:next()
do
	language=I:value("language")
	items=items+1
	if language == nil then language="none" end

	val=langs[language]
	if val == nil then langs[language]=1 
	else langs[language]=val+1
	end

	if LanguageInSearch(search_languages, language)
	then
		print(t.format("~e~g" .. I:value("name") .. "~0") .. "    lang: " .. language .. "  watchers:" .. I:value("watchers") .. "  forks:" .. I:value("forks") .. "    " .. t.format("~b" .. I:value("html_url") .. "~0"))
		print(I:value("description"))
		print()
	end
end

table.sort(langs)
io.write(t.format("~m"..items.." items: "))
for key,value in pairs(langs)
do
	io.write(key.." "..value..", ")
end
print(t.format("~0"))
end




function BuildStringList(list, str)
	if list == nil 
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
print("   -l       <language list>  - languages to consider")
print("   -lang    <language list>  - languages to consider")
print("   -s       <sort key>       - sort results, descending order. Key can be 'stars', 'forks' or 'updated'.")
print("   +s       <sort key>       - sort results, ascending order. Key can be 'stars', 'forks' or 'updated'.")
print("   -stars   <number>         - minimum number of stars/watches that a result must have.")
print("   -S       <number>         - minimum number of stars/watches that a result must have.")
print("   -w       <number>         - minimum number of stars/watches that a result must have.")
print("   -watches <number>         - minimum number of stars/watches that a result must have.")
print("   -p       <proxy url>      - use a proxy")
print("   -proxy   <proxy url>      - use a proxy")
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
print("examples:")
print("   lua github-search honeypot                    - search for things matching 'honeypot'")
print("   lua github-search ssh honeypot                - search for things matching 'ssh honeypot'")
print("   lua github-search -l c++,go ssh honeypot      - search for things matching 'ssh honeypot' and written in either c++ or go")
end



function ParseCommandLine(args)
local lang
local query=""
local langs=""
local lang_lists=""
local sort=""

for i,v in ipairs(args)
do
	if v == '-l' or v == '-lang'
	then
			if string.len(langs) ==0 then langs=args[i+1] end
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
	elseif v == '-p' or v == '-proxy'
	then
		proxy=args[i+1]
		args[i+1]=""
	elseif v == '-?' or v == '-h' or v == '-help' or v == '--help'
	then
		PrintHelp()
		process.exit(0);
	else
		if string.len(query) > 0 then query=query.." " end
		query=query .. v
	end
end


if string.len(query) < 1
then
	print("Please supply a search term on the command line")
	process.exit(0)
end


return query,langs,qlang,sort
end





function ConnectedOkay(S)

if S == nil then return false end

ResponseCode=S:getvalue("HTTP:ResponseCode")
if ResponseCode == "200" then return true end

return false
end




-- lu_set sets values that change libUseful's behavior, here we set the default user-agent string for this script
process.lu_set("HTTP:UserAgent","Colums Github Search Script")

query,languages,qlang,sort=ParseCommandLine(arg)

if string.len(proxy) then net.setProxy(proxy) end

Qquery=strutil.httpQuote(query);
Qlanguage=strutil.httpQuote(qlang);

url="https://api.github.com/search/repositories?q=" .. Qquery .. "&language=" .. Qlanguage .. "&sort="..sort.."&per_page=100";

print("QUERY: "..url)
S=stream.STREAM(url);
if ConnectedOkay(S)
then
	doc=S:readdoc()
	ParseReply(doc, languages)
end


