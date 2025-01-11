#!/usr/bin/gawk -bE     

#
# flmbot - bot description
#

# The MIT License (MIT)
#    
# Copyright (c) December 2024-2025
#   
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR                   
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

BEGIN { # Bot cfg

  _defaults = "home      = /home/greenc/toolforge/flmbot/ \
               emailfp   = /home/greenc/toolforge/scripts/secrets/greenc.email \
               version   = 1.1 \
               copyright = 2025"

  asplit(G, _defaults, "[ ]*[=][ ]*", "[ ]{9,}")
  BotName = "flmbot"
  Home = G["home"]
  Engine = 3

  IGNORECASE = 1

  G["data"] = G["home"] "data/"
  G["meta"] = G["home"] "meta/"
  G["logfile"] = G["meta"] "logflmbot"

}

@include "botwiki.awk"
@include "library.awk"
@include "json.awk"

BEGIN { # Bot run

  G["email"] = readfile(G["emailfp"])
  Agent = "Ask me about " BotName " - " G["email"]

  main()
}

# ----------------------------------------------

#
# Current time
#
function curtime(  style) {
  if(!empty(style))
    return sys2var(Exe["date"] " -u +\"%Y-%m-%d at %H:%M:%S\"")
  return sys2var(Exe["date"] " -u +\"%Y-%m-%dT%H:%M:%S\"")
}

#
# Return s with first letter capitalized
#
function firstCap(s) {
  return toupper(substr(s, 1, 1)) substr(s, 2)
}

#
# Uniq a list of \n separated names
#
function uniq(names,    b,c,i,x) {

        c = split(names, b, "\n")
        names = "" # free memory
        while (i++ < c) {
            if (b[i] == "")
                continue
            if (x[b[i]] == "")
                x[b[i]] = b[i]
        }
        delete b # free memory
        return join2(x, "\n")
}


#
# sorta() - given a \n sep string, return the characters in a sorted_in 'order'
#
#   Example
#      sorta("GteWdAa\nBtdgf", "@val_str_asc") => Btdgf\nGteWdAa
#
#   . for other 'order' sort options
#       https://www.gnu.org/software/gawk/manual/html_node/Controlling-Scanning.html
#
function sorta(s,order,  a,b) {

    if("sorted_in" in PROCINFO)
        save_sorted = PROCINFO["sorted_in"]
    PROCINFO["sorted_in"] = "@val_str_asc"

    split(s, a, "\n")
    asort(a)
    b = join(a, 1, length(a), "\n")

    if (save_sorted)
        PROCINFO["sorted_in"] = save_sorted
    else
        PROCINFO["sorted_in"] = ""

    return strip(b)
}


#
# Clean empty lines and other garbage from \n sep string
#
function clearnl(s, out,a,i) {

  for(i = 1; i <= splitn(s, a, i); i++) {
    if(a[i] ~ /^([_]{2}|[{]{2}|[<]|[[]{2})/)
      continue
    if(a[i] ~ /Talk[:]/)
      sub(/Talk[:]/, "", a[i])
    if(i == 1)
      out = a[i]
    else
      out = out "\n" a[i]
  }
  return strip(out)
}

#
# Loop retry remote page via wikiget
#
function wikiget(command,  i,fp) {

  for(i = 1; i <= 20 ; i++) {
    fp = sys2var(command)
    if(!empty(fp)) return fp
    sleep(2, "unix")
  }

}

#
# Generate report
#
function report(  list,i,a,k,opend,closed) {

  opend  = "{{div col|colwidth=20em}}"
  closed = "{{div col end}}"

  print "" > G["data"] "report"
  print "{{Documentation}}" >> G["data"] "report"

  print "== In [[:Category:Featured lists]] but not [[:Category:Wikipedia featured lists]] ==" >> G["data"] "report"
  list = sorta(uniq(sys2var(Exe["grep"] " -vxF -f " G["data"] "listwfl " G["data"] "listfl")))
  for(i = 1; i <= splitn(list "\n", a, i); i++) {
    print "# [[:" a[i] "]]" >> G["data"] "report"
    Sweep[a[i]] = 1
  }

  print "\n== In [[:Category:Wikipedia featured lists]] but not in [[:Category:Featured lists]] ==" >> G["data"] "report"
  list = sorta(uniq(sys2var(Exe["grep"] " -vxF -f " G["data"] "listfl " G["data"] "listwfl")))
  for(i = 1; i <= splitn(list "\n", a, i); i++) {
    print "# [[:Talk:" a[i] "]]" >> G["data"] "report"
    Sweep[a[i]] = 1
  }

  print "\n== In [[:Category:Featured lists]] but not on [[:Wikipedia:Featured lists]] ==" >> G["data"] "report"
  list = sorta(uniq(sys2var(Exe["grep"] " -vxF -f " G["data"] "listfla " G["data"] "listfl")))
  for(i = 1; i <= splitn(list "\n", a, i); i++) {
    if( isinredir(a[i]) == 0 ) {
      print "# [[:" a[i] "]]" >> G["data"] "report"
      Sweep[a[i]] = 1
    }
  }

  print "\n== In [[:Category:Wikipedia featured list candidates]] but not on [[:Wikipedia:Featured list candidates]] ==" >> G["data"] "report"
  list = sorta(uniq(sys2var(Exe["grep"] " -vxF -f " G["data"] "listflc " G["data"] "listwflc")))
  for(i = 1; i <= splitn(list "\n", a, i); i++) {
    if( isinredir(a[i]) == 0 ) {
      print "# [[:" a[i] "]]" >> G["data"] "report"
      Sweep[a[i]] = 1
    }
  }

  print "\n== In [[:Wikipedia:Featured lists]] but not in [[:Category:Featured lists]] ==" >> G["data"] "report"
  list = sorta(uniq(sys2var(Exe["grep"] " -vxF -f " G["data"] "listfl " G["data"] "listfla")))
  for(i = 1; i <= splitn(list "\n", a, i); i++) {
    if( Redirs[a[i]] == 0 ) {
      print "# [[:" a[i] "]]" >> G["data"] "report"
      Sweep[a[i]] = 1
    }
  }

  print "\n== Redirects in [[:Wikipedia:Featured lists]] ==" >> G["data"] "report"
  for(k in Redirs) {
    if(Redirs[k] != 0 && k !~ "-Hydroxy β-methylbutyric acid") {
      print "# [[:" k "]] --> [[:" Redirs[k] "]]" >> G["data"] "report"
      Sweep[k] = 1
    }
  }

  print "\n{{ombox | text = Report generated " curtime("space") " by '''[[User:GreenC bot/Job 15|flmbot]]'''.}}" >> G["data"] "report"
 
}

#
# Return true if a namewiki is in a value field of Redirs[] anywhere
#
function isinredir(namewiki, i) {

  IGNORECASE = 0
  for(i in Redirs) {
    if(Redirs[i] == namewiki) {
      IGNORECASE = 1
      return 1
    }
  }
  IGNORECASE = 1
  return 0
}

#
# Return 1 if a redirect
#
function isredirect(namewiki,  jsonin,jsona,command) {

  command = "https://en.wikipedia.org/w/api.php?action=query&titles=" urlencodeawk(strip(namewiki)) "&prop=info&formatversion=2&format=json"
  jsonin = http2var(command)
  if( query_json(jsonin, jsona) >= 0) {
    if(jsona["query","pages","1","redirect"] == 1) 
      return 1
  }
  return 0
}

#
# Return the target for a redirect
#
function whatisredirect(namewiki,  jsonin,jsona,command) {

  command = "https://en.wikipedia.org/w/api.php?action=query&titles=" urlencodeawk(strip(namewiki)) "&redirects&format=json&formatversion=2"
  jsonin = http2var(command)
  if( query_json(jsonin, jsona) >= 0) {
    # Might be more than one but get first one 
    if(length(jsona["query","redirects","1","to"]) > 0) 
      return jsona["query","redirects","1","to"]
  }
  return 0

}

#
# Populate Redirs[] with titles in listfla that are redirects
#
function getredirects( pos,i,a) {

  # If in Featured lists/all but not Category:Featured lists
  # Check each for redirect 
  pos = sys2var(Exe["grep"] " -vxF -f " G["data"] "listfl " G["data"] "listfla")  
  for(i = 1; i <= splitn(pos "\n", a, i); i++) {
    if(isredirect(a[i])) 
      Redirs[a[i]] = whatisredirect(a[i])
    else
      Redirs[a[i]] = 0
  }

}

#
# Get articles in Wikipedia:Featured list candidates
#
function getlistflc(   fp,field,sep,i,result,c) {

  fp = wikiget(Exe["wikiget"] " -w " shquote("Wikipedia:Featured list candidates") )
  if(empty(fp)) 
    return ""

  # {{Wikipedia:Featured list candidates/Svalbard discography/archive1}}
  c = patsplit(fp, field, /[{]{2}Wikipedia:Featured list candidates\/[^}]*[}]{2}/, sep)
  for(i = 1; i <= c; i++) {
    if(field[i] !~ /\/archive[0-9]/) continue
    sub(/[{]{2}[ ]*Wikipedia:Featured[ _]list[ _]candidates\//, "", field[i])
    sub(/\/archive[0-9][ ]*[}]{2}$/, "", field[i])
    result = result "\n" field[i]
  }
  result = strip(result)

  if(!length(result)) {
    sendlog(G["logfile"], curtime() " ---- Empty result[] for Wikipedia:Featured_list_candiates. Breakpoint A")
    return ""
  }
 
  return result

}


#
# Get articles in Wikipedia:Featured lists
#
function getlistfla(   fp,k,i,a,spot,dest,result,command,firstsect,re,d) {

  fp = wikiget(Exe["wikiget"] " -w " shquote("Wikipedia:Featured lists") )
  if(empty(fp)) 
    return ""


  # This block doesn't work in Featured lists, because the section index is different from the section titles! 
  # For now just hard-coding for parsing to start at "__NOTOC__"

  for(i = 1; i <= splitn(fp, a, i); i++) {
    # [[#Art, architecture, and archaeology|Art, architecture, and archaeology]
    if(a[i] ~ /^[*][ ]*[[]{2}[ ]*[#]/) {
      if(match(a[i], /[#][^|]+[^|]/, d) > 0) {
        firstsect = d[0]
        sub(/[#]/, "", firstsect)
        firstsect = strip(firstsect)
        break
      }
    }
  }

  if(empty(firstsect)) {
    sendlog(G["logfile"], curtime() " ---- Unable to find first section title. Breakpoint A.2")
    return ""
  }

  k = 1
  # re = "^==[ ]*" regesc3(firstsect) "[ ]*==[ ]*$"
  re = "__NOTOC__"

  for(i = 1; i <= splitn(fp, a, i); i++) {
    if(spot == 0 && a[i] ~ re) 
      spot = 1
    if(spot) {

      a[i] = stripwikicomments(a[i])

      # * [[...]]|{{FL/...}}
      # "[[...]]|{{FL/...}}
      # ''[[...]]|{{FL/...}}
      if(a[i] ~ /^[ ]*([']{1,5}|["]|[*])?[ ]*([{]{2}FL[/]|[[]{2})/) {

        if(match(a[i], /[[]{2}[^\]|]+[^\]|]/, d) > 0) {
          sub(/^[[]{2}/, "", d[0])
          if(d[0] ~ /^Category:/) continue
          result[k++] = strip(firstCap(d[0]))
        }
      }
    }
  }

  if(!length(result)) {
    sendlog(G["logfile"], curtime() " ---- Empty result[] for Wikipedia:Featured_lists. Breakpoint B")
    return ""
  }
 
  fp = ""
  for(k in result) 
    fp = fp "\n" result[k]

  if(empty(fp)) {
    sendlog(G["logfile"], curtime() " ---- Empty fp for |" result[k] "|. Breakpoint C")
    return ""
  }
  return fp

}

#
# Get lists
#
function getlists(   listwfl,listfl,listfla) {

  # Category:Wikipedia featured lists

  listwfl = clearnl(wikiget(Exe["wikiget"] " -c " shquote("Wikipedia featured lists") " | " Exe["grep"] " -vE " shquote("(Wikipedia:|Template:)") ))
  if(empty(listwfl)) 
    sendlog(G["logfile"], curtime() " ---- Empty fp for Category:Wikipedia_featured_lists")

  # Category:Featured lists

  listfl = clearnl(wikiget(Exe["wikiget"] " -c " shquote("Featured lists") " | " Exe["grep"] " -vE " shquote("(Wikipedia:|Template:)") ))
  if(empty(listfl)) 
    sendlog(G["logfile"], curtime() " ---- Empty fp for Category:Featured_lists")

  # Category:Wikipedia featured list candidates

  listwflc = clearnl(wikiget(Exe["wikiget"] " -c " shquote("Wikipedia featured list candidates") " | " Exe["grep"] " -vE " shquote("(Wikipedia:|Template:)") ))
  if(empty(listwflc)) 
    sendlog(G["logfile"], curtime() " ---- Empty fp for Category:Wikipedia_featured_list_candidates")

  # Wikipedia:Featured list candidates

  listflc = clearnl(getlistflc())
  if(empty(listflc)) 
    sendlog(G["logfile"], curtime() " ---- Empty fp for Wikipedia:Featured_list_candidates")

  # Wikipedia:Featured lists

  listfla = clearnl(getlistfla())
  if(empty(listfla)) 
    sendlog(G["logfile"], curtime() " ---- Empty fp for Wikipedia:Featured_lists")

  if( countsubstring(listwfl, "\n") < 4000 || countsubstring(listfl, "\n") < 4000 || countsubstring(listfla, "\n") < 4000) {
    sendlog(G["logfile"], curtime() " ---- List(s) too short. Program Aborted.")
    #print listwfl > G["meta"] "listwfa"
    #print listfl > G["meta"] "listfa"
    #print listfla > G["meta"] "listfaa"
    if(countsubstring(listfla, "\n") < 4000 && countsubstring(listfl, "\n") > 4000 && countsubstring(listfla, "\n") > 4000) {
      print "Bot error: trouble parsing [[Wikipedia:Featured lists]] - page format changed? Please contact [[User:GreenC]]" > G["data"] "report"
      close(G["data"] "report")
      upload(readfile(G["data"] "report"), "Wikipedia:Featured lists/mismatches", "Bot error: trouble parsing [[Wikipedia:Featured lists]]", G["meta"], BotName, "en")
    }
    exit
  }

  print listwfl > G["data"] "listwfl"; close(G["data"] "listwfl")
  print listwflc > G["data"] "listwflc"; close(G["data"] "listwflc")
  print listflc > G["data"] "listflc"; close(G["data"] "listflc")
  print listfl > G["data"] "listfl"; close(G["data"] "listfl")
  print listfla > G["data"] "listfla"; close(G["data"] "listfla")

}

function main(  ls) {

  delete Sweep   # number of new changes by article name
  getlists()
  getredirects()
  report()

  ls = int(length(Sweep))
  if(ls > 0) {
    if(ls < 2)
      G["summary"] = "1 page needs help (report by [[User:GreenC bot/Job 15|flmbot]])"
    else
      G["summary"] = ls " pages need help (report by [[User:GreenC bot/Job 15|flmbot]]"
  }
  else
    G["summary"] = "No problems detected (report by [[User:GreenC bot/Job 15|flmbot]])"

  close(G["data"] "report")
  #upload(readfile(G["data"] "report"), "Wikipedia:Featured lists/mismatches", G["summary"], G["meta"], BotName, "en")

}
