github-search: copyright Colum Paget 2017
contact: colums.projects@github.com
license: GPLv3

This is just a basic command-line repository search tool for github. It requires both libUseful and libUseful-lua to be installed. These are available at:

```
https://www.github.com/ColumPaget/libUseful 
https://www.github.com/ColumPaget/libUseful-lua 
```

you will also need SWIG installed to compile libUseful-lua (http://www.swig.org)


You can search by keywords combined with language that the project should be written in and the minimum number of stars/watches that it has. You can change the sort order and use a proxy for all communications.

```
usage:  lua github-search.lua [options] [search terms]

   -l       <language list>  - languages to consider
   -lang    <language list>  - languages to consider
   -s       <sort key>       - sort results, descending order. Key can be 'stars', 'forks' or 'updated'.
   +s       <sort key>       - sort results, ascending order. Key can be 'stars', 'forks' or 'updated'.
   -stars   <number>         - minimum number of stars/watches that a result must have.
   -S       <number>         - minimum number of stars/watches that a result must have.
   -w       <number>         - minimum number of stars/watches that a result must have.
   -watches <number>         - minimum number of stars/watches that a result must have.
   -p       <proxy url>      - use a proxy
   -proxy   <proxy url>      - use a proxy
   -?       this help
   -h       this help
   -help    this help
   --help   this help

proxy urls can be are in the format <protocol>:<user>:<password>@<host>:<port>. all attributes but protcol and host are optional.
proxy protocols can be:
   ssh          pipe through ssh (ssh -w option)
   sshtunnel    use ssh port forwarding, port automatically selected (ssh -L option)
   socks4       socks4 protocol
   socks5       socks5 protocol
   https        https CONNECT proxy

examples:
   lua github-search honeypot                    - search for things matching 'honeypot'
   lua github-search ssh honeypot                - search for things matching 'ssh honeypot'
   lua github-search -l c++,go ssh honeypot      - search for things matching 'ssh honeypot' and written in either c++ or go
```
