## github-search: copyright Colum Paget 2017
contact: colums.projects@github.com
license: GPLv3

This is just a basic command-line repository search tool for github. It requires both libUseful and libUseful-lua to be installed. These are available at:

```
https://www.github.com/ColumPaget/libUseful 
https://www.github.com/ColumPaget/libUseful-lua 
```

you will also need SWIG installed to compile libUseful-lua (http://www.swig.org)


You can search by keywords combined with language that the project should be written in and the minimum number of stars/watches that it has. You can change the sort order and use a proxy for all communications.

## strange results

github takes the 'language' argument, as supplied by '-l' or '-L' as a hint, not a hard requirement, and will include results from languages you didn't ask for. This can produce some strange results with the '-L' option. The '-L' option applies a post-filter, eliminating any results that weren't in the language asked for. Imagine that you make this query:

```
	lua github-search -S 100 honeypot -L go
```

You don't get many results, so you lower the requirements on stars/watches:

```
	lua github-search -S 50 honeypot -L go
```

You might actually see FEWER results! This is because github has returned more results that aren't in your chosen language, and has pushed some of the results that are out of the list. You can somewhat overcome this by using the '-n' option to force querying until the desired number of results are returned.


```
usage:  lua github-search.lua [options] [search terms]
   -lang    <language list>  - languages to consider
   -L       <language list>  - post filter results to show ONLY this language
   -s       <sort key>       - sort results, descending order. Key can be 'stars', 'forks' or 'updated'.
   +s       <sort key>       - sort results, ascending order. Key can be 'stars', 'forks' or 'updated'.
   -stars   <number>         - minimum number of stars/watches that a result must have.
   -S       <number>         - minimum number of stars/watches that a result must have.
   -w       <number>         - minimum number of stars/watches that a result must have.
   -watches <number>         - minimum number of stars/watches that a result must have.
   -created <date>           - created since date.
   -since   <date>           - updated since date.
   -n <number>               - minimum number of results to display. When used with -L filter, it's results displayed, not returned.
   -dl <number>              - maximum number of characters to show of description, defaults to 300. This is to deal with annoying people who write
 novellas in their project description. Set to -dl 0 if you really want to read their magnum opus.
   -Q <number>               - change guard level of number of failed results before giving up.
   -p       <proxy url>      - use a proxy
   -proxy   <proxy url>      - use a proxy
   -version  program version
   -?       this help
   -h       this help
   -help    this help
   --help   this help

```

proxy urls can be are in the format 
```
<protocol>:<user>:<password>@<host>:<port>
```

all attributes but protcol and host are optional.

```
proxy protocols can be:
   ssh          pipe through ssh (ssh -w option)
   sshtunnel    use ssh port forwarding, port automatically selected (ssh -L option)
   socks4       socks4 protocol
   socks5       socks5 protocol
   https        https CONNECT proxy

```

-L applies a post-filter on the results, as github takes the language argument as a hint, not a hard requirement. Thus with -L github can return 100 results, but if only 3 of them are in your required language, only three are displayed, unlike '-l' which will display all 100. -n can be used to insist we keep pulling pages until a certain number are displayed.

However, even if '-n' is used, if more than 100 results are returned with no matches displayed, the search will return an error. You can change this limit using '-Q', but be aware that the search service is rate-limited, and pulling too many results can get you locked out for a time.

```
examples:
   lua github-search honeypot                    - search for things matching 'honeypot'
   lua github-search ssh honeypot                - search for things matching 'ssh honeypot'
   lua github-search -l c++,go ssh honeypot      - search for things matching 'ssh honeypot' written in either c++ or go
   lua github-search -n 10 -l go honeypot        - search for 'honeypot' written in go, until at least 10 displayed
```
