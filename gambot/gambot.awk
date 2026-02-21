#!/usr/local/bin/gawk -bE     

#
# gambot - bot description
#

# The MIT License (MIT)
#    
# Copyright (c) April 2019-2025
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

  _defaults = "home      = /home/greenc/toolforge/gambot/ \
               emailfp   = /home/greenc/toolforge/scripts/secrets/greenc.email \
               summary   = Report updated (by [[User:GreenC bot/Job 15|gambot]]) \
               userid    = User:GreenC \
               version   = 1.0 \
               copyright = 2025"

  asplit(G, _defaults, "[ ]*[=][ ]*", "[ ]{9,}")
  BotName = "gambot"
  Home = G["home"]
  Engine = 3

  # Agent string format non-compliance could result in 429 (too many requests) rejections by WMF API
  Agent = BotName "-" G["version"] "-" G["copyright"] " (" G["userid"] "; mailto:" strip(readfile(G["emailfp"])) ")"

  IGNORECASE = 1

  G["data"] = G["home"] "data/"
  G["meta"] = G["home"] "meta/"
  G["logfile"] = G["meta"] "loggambot"

}

@include "botwiki.awk"
@include "library.awk"
@include "json.awk"

BEGIN { # Bot run

  main()
  healthcheckwatch()

}

#
# https://github.com/greencardamom/HealthcheckWatch
# acre:[/home/greenc/toolforge/healthcheckwatch]
#
function healthcheckwatch(  command) {

  command = "/usr/bin/curl -s -X POST " shquote("https://healthcheckwatch.wbcqanjidyjcjbe.workers.dev/ping/acre-gambot") " -H " shquote("Authorization: Bearer Xn*izT%(^pI8J/q+Mn*ipT%(^pI9J/q") " -H " shquote("Content-Type: application/json") " -d " shquote("{ \"timeout\": 75, \"subject\": \"NOTIFY (HCW): gambot.awk\", \"body\": \"acre: /home/greenc/toolforge/gambot/gambot.awk (no response)\" }")
  system(command)
  exit

}


#
# Current time
#
function curtime(  style) {
  if(!empty(style))
    return sys2var(Exe["date"] " -u +\"%Y-%m-%d at %H:%M:%S\"")
  return sys2var(Exe["date"] " -u +\"%Y-%m-%dT%H:%M:%S\"")
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

  print "== In [[:Category:Good articles]] but not [[:Category:Wikipedia good articles]] ==" >> G["data"] "report"
  # print opend >> G["data"] "report"
  list = sorta(uniq(sys2var(Exe["grep"] " -vxF -f " G["data"] "listwga " G["data"] "listga")))
  for(i = 1; i <= splitn(list "\n", a, i); i++) 
    print "# [[:" a[i] "]]" >> G["data"] "report"
  # print closed >> G["data"] "report"

  print "\n== In [[:Category:Wikipedia good articles]] but not in [[:Category:Good articles]] ==" >> G["data"] "report"
  # print opend >> G["data"] "report"
  list = sorta(uniq(sys2var(Exe["grep"] " -vxF -f " G["data"] "listga " G["data"] "listwga")))
  for(i = 1; i <= splitn(list "\n", a, i); i++) 
    print "# [[:Talk:" a[i] "]]" >> G["data"] "report"
  # print closed >> G["data"] "report"

  print "\n== In [[:Category:Good articles]] but not on [[:Wikipedia:Good articles/all]] ==" >> G["data"] "report"
  # print opend >> G["data"] "report"
  list = sorta(uniq(sys2var(Exe["grep"] " -vxF -f " G["data"] "listgaa " G["data"] "listga")))
  for(i = 1; i <= splitn(list "\n", a, i); i++) {
    if( isinredir(a[i]) == 0 )
      print "# [[:" a[i] "]]" >> G["data"] "report"
  }
  # print closed >> G["data"] "report"

  print "\n== On [[:Wikipedia:Good articles/all]] but not in [[:Category:Good articles]] ==" >> G["data"] "report"
  # print opend >> G["data"] "report"
  list = sorta(uniq(sys2var(Exe["grep"] " -vxF -f " G["data"] "listga " G["data"] "listgaa")))
  for(i = 1; i <= splitn(list "\n", a, i); i++) {
    if( Redirs[a[i]] == 0 )
      print "# [[:" a[i] "]]" >> G["data"] "report"
  }
  # print closed >> G["data"] "report"

  print "\n== Redirects in [[:Wikipedia:Good articles/all]] ==" >> G["data"] "report"
  # print opend >> G["data"] "report"
  for(k in Redirs) {
    if(Redirs[k] != 0)   
      print "# [[:" k "]] --> [[:" Redirs[k] "]]" >> G["data"] "report"
  }
  # print closed >> G["data"] "report"

  print "\n{{ombox | text = Report generated " curtime("space") " by '''[[User:GreenC bot/Job 15|gambot]]'''.}}" >> G["data"] "report"
 
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
# Populate Redirs[] with titles in listgaa that are redirects
#
function getredirects( pos,i,a) {

  # If in Good Article/all but not Category:Good Article
  # Check each for redirect 
  pos = sys2var(Exe["grep"] " -vxF -f " G["data"] "listga " G["data"] "listgaa")  
  for(i = 1; i <= splitn(pos "\n", a, i); i++) {
    if(isredirect(a[i])) 
      Redirs[a[i]] = whatisredirect(a[i])
    else
      Redirs[a[i]] = 0
  }

}

#
# Get articles in Wikipedia:Good_articles/all
#
function getlistgaa(   fp,k,i,a,b,d,spot,dest,result,command) {

# Wikipedia:Good_articles/all
## <!-- Do not remove this line, LivingBot relies on it to distinguish the above from the below. Thanks. -->
## {{Wikipedia:Good articles/Agriculture, food and drink}}
## etc..
### [[Agriculture]]&nbsp;–
### etc..

  fp = wikiget(Exe["wikiget"] " -w " shquote("Wikipedia:Good_articles/all") )
  if(empty(fp)) 
    return ""

  k = 1
  for(i = 1; i <= splitn(fp "\n", a, i); i++) {
    if(spot == 0 && a[i] ~ /==[ ]*Contents?[ ]*==/)
      spot = 1
    if(spot) {
      if(a[i] ~ "*[ ]*[[]{2}") {
        if(match(a[i], /[[]{2}[^]]*[^]]/, d) > 0) {
          sub("^[[]{2}", "", d[0])
          split(d[0], b, "[|]")
          if(b[1] ~ "^#")
            b[1] = "Wikipedia:Good articles/all" b[1]
          result[k++] = strip(b[1])
        }
      }
    }
    if(a[i] ~ /[{]{2}endplainlist[}]{2}/)
      spot = 0

  }

  if(!length(result)) {
    sendlog(G["logfile"], curtime() " ---- Empty result[] for Wikipedia:Good_articles/all. Breakpoint B")
    return ""
  }
 
  fp = ""
  for(k in result) {
    command = Exe["wikiget"] " -F " shquote(result[k]) " | " Exe["grep"] " -vE \"Wikipedia[:]|Wikipedia talk[:]|Category[:]|Category talk[:]\"" 
    if(!empty(fp))      
      fp = fp "\n" wikiget(command)
    else
      fp = wikiget(command)      
  }
  if(empty(fp)) {
    sendlog(G["logfile"], curtime() " ---- Empty fp for |" result[k] "|. Breakpoint C")
    return ""
  }

  # uniqe the list which somehow gets duplicates
  delete result
  for(i = 1; i <= splitn(fp "\n", a, i); i++) {
    if(empty(a[i])) continue
    result[strip(a[i])] = i
  }
  fp = ""
  for(k in result)
    if(!empty(fp))
      fp = fp "\n" k
    else
      fp = k

  return fp

}

#
# Get lists
#
function getlists(   listwga,listga,listgaa) {

  # Category:Wikipedia good articles

  listwga = clearnl(wikiget(Exe["wikiget"] " -c " shquote("Wikipedia good articles") ))
  #listwga = readfile(G["data"] "listwga")
  if(empty(listwga))
    sendlog(G["logfile"], curtime() " ---- Empty fp for Category:Wikipedia_good_articles")

  # stdErr("listwga = " countsubstring(listwga, "\n"))

  # Category:Good articles

  listga = clearnl(wikiget(Exe["wikiget"] " -c " shquote("Good articles") ))
  #listga = readfile(G["data"] "listga")
  if(empty(listga))
    sendlog(G["logfile"], curtime() " ---- Empty fp for Category:Good_articles")

  # stdErr("listga = " countsubstring(listga, "\n"))

  # Wikipedia:Good articles

  listgaa = clearnl(getlistgaa())
  #listgaa = readfile(G["data"] "listgaa")
  if(empty(listgaa))
    sendlog(G["logfile"], curtime() " ---- Empty fp for Wikipedia:Good_articles")    

  # stdErr("listgaa = " countsubstring(listgaa, "\n"))

  if( countsubstring(listwga, "\n") < 38000 || countsubstring(listga, "\n") < 38000 || countsubstring(listgaa, "\n") < 38000) {
    sendlog(G["logfile"], curtime() " ---- List(s) too short. Program Aborted.")
    print "___________________ ---- listwga ---- " countsubstring(listwga, "\n") >> G["logfile"]
    print "___________________ ---- listga ---- " countsubstring(listga, "\n") >> G["logfile"]
    print "___________________ ---- listgaa ---- " countsubstring(listgaa, "\n") >> G["logfile"]
    close(G["logfile"])
    email(Exe["from_email"], Exe["to_email"], "NOTIFY: " BotName " - List(s) too short. Program aborted. See " G["home"] "meta/loggambot", "")
    exit
  }

  print listwga > G["data"] "listwga"
  print listga > G["data"] "listga"
  print listgaa > G["data"] "listgaa"

  close(G["data"] "listwga")
  close(G["data"] "listga")
  close(G["data"] "listgaa")

}

function main(  res) {

  getlists()
  getredirects()
  report()
  close(G["data"] "report")
  res = upload(readfile(G["data"] "report"), "Wikipedia:Good articles/mismatches", G["summary"], G["meta"], BotName, "en")
  if(res)
    print sys2var(Exe["date"] " +\"%Y%m%d-%H:%M:%S\"") " ---- success" >> G["meta"] "upload"
  else
    print sys2var(Exe["date"] " +\"%Y%m%d-%H:%M:%S\"") " ---- failed" >> G["meta"] "upload"

}


