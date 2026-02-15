#!/usr/local/bin/gawk -bE     

#
# fambot - bot description
#

# The MIT License (MIT)
#    
# Copyright (c) December 2021-2025
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

  _defaults = "home      = /home/greenc/toolforge/fambot/ \
               emailfp   = /home/greenc/toolforge/scripts/secrets/greenc.email \
               userid    = User:GreenC \
               version   = 1.1 \
               copyright = 2025"

  asplit(G, _defaults, "[ ]*[=][ ]*", "[ ]{9,}")
  BotName = "fambot"
  Home = G["home"]
  Engine = 3

  # Agent string format non-compliance could result in 429 (too many requests) rejections by WMF API
  Agent = BotName "-" G["version"] "-" G["copyright"] " (" G["userid"] "; mailto:" strip(readfile(G["emailfp"])) ")"

  IGNORECASE = 1

  G["data"] = G["home"] "data/"
  G["meta"] = G["home"] "meta/"
  G["logfile"] = G["meta"] "logfambot"

  # Note: B-Hydroxy β-methylbutyric acid is a PITA. Couple things need to be maintained
  #
  #       1. WP:Featured_articles need to have a line like this:
  #          {{FA/BeenOnMainPage|[[Β-Hydroxy β-methylbutyric acid|β-Hydroxy β-methylbutyric<!-- Do not modify this line without first discussing with User:GreenC --> acid]]}}
  #       2. Notice the leading "B" is not Latin B, it is Greek Β. They visually look exactly the same but not.
  #       3. This program has some special code for dealing with redirects search on "hydroxy" - not sure it's still needed
  #       4. There is a redirect for the Latin B version on-wiki that might need to be maintained - not sure it's still needed

}

@include "botwiki.awk"
@include "library.awk"
@include "json.awk"

BEGIN { # Bot run

  main()
  
  healthcheckwatch()
}

# ----------------------------------------------

#
# https://github.com/greencardamom/HealthcheckWatch
# acre:[/home/greenc/toolforge/healthcheckwatch]
#
function healthcheckwatch(  command) {

  command = "/usr/bin/curl -s -X POST " shquote("https://healthcheckwatch.wbcqanjidyjcjbe.workers.dev/ping/acre-fambot") " -H " shquote("Authorization: Bearer Xn*izT%(^pI8J/q+Mn*ipT%(^pI9J/q") " -H " shquote("Content-Type: application/json") " -d " shquote("{ \"timeout\": 170, \"subject\": \"NOTIFY (HCW): fambot.awk\", \"body\": \"acre: /home/greenc/toolforge/fambot/fambot.awk (no response)\" }")
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
function report(  list,i,a,k,opend,closed,usecol) {

  usecol = 0
  opend  = "{{div col|colwidth=20em}}"
  closed = "{{div col end}}"

  print "" > G["data"] "report"
  print "{{Documentation}}" >> G["data"] "report"

  print "== In [[:Category:Featured articles]] but not [[:Category:Wikipedia featured articles]] ==" >> G["data"] "report"
  if(usecol) print opend >> G["data"] "report"
  list = sorta(uniq(sys2var(Exe["grep"] " -vxF -f " G["data"] "listwfa " G["data"] "listfa")))
  for(i = 1; i <= splitn(list "\n", a, i); i++) {
    print "# [[:" a[i] "]]" >> G["data"] "report"
    Sweep[a[i]] = 1
  }
  if(usecol) print closed >> G["data"] "report"

  print "\n== In [[:Category:Wikipedia featured articles]] but not in [[:Category:Featured articles]] ==" >> G["data"] "report"
  if(usecol) print opend >> G["data"] "report"
  list = sorta(uniq(sys2var(Exe["grep"] " -vxF -f " G["data"] "listfa " G["data"] "listwfa")))
  for(i = 1; i <= splitn(list "\n", a, i); i++) {
    print "# [[:Talk:" a[i] "]]" >> G["data"] "report"
    Sweep[a[i]] = 1
  }
  if(usecol) print closed >> G["data"] "report"

  print "\n== In [[:Category:Featured articles]] but not on [[:Wikipedia:Featured articles]] ==" >> G["data"] "report"
  if(usecol) print opend >> G["data"] "report"
  list = sorta(uniq(sys2var(Exe["grep"] " -vxF -f " G["data"] "listfaa " G["data"] "listfa")))
  for(i = 1; i <= splitn(list "\n", a, i); i++) {
    if( isinredir(a[i]) == 0 ) {
      print "# [[:" a[i] "]]" >> G["data"] "report"
      Sweep[a[i]] = 1
    }
  }
  if(usecol) print closed >> G["data"] "report"

  print "\n== In [[:Category:Wikipedia featured article candidates]] but not on [[:Wikipedia:Featured article candidates]] ==" >> G["data"] "report"
  if(usecol) print opend >> G["data"] "report"
  list = sorta(uniq(sys2var(Exe["grep"] " -vxF -f " G["data"] "listfac " G["data"] "listwfac")))
  for(i = 1; i <= splitn(list "\n", a, i); i++) {
    if( isinredir(a[i]) == 0 ) {
      print "# [[:" a[i] "]]" >> G["data"] "report"
      Sweep[a[i]] = 1
    }
  }
  if(usecol) print closed >> G["data"] "report"

  print "\n== In [[:Wikipedia:Featured articles]] but not in [[:Category:Featured articles]] ==" >> G["data"] "report"
  if(usecol) print opend >> G["data"] "report"
  list = sorta(uniq(sys2var(Exe["grep"] " -vxF -f " G["data"] "listfa " G["data"] "listfaa")))
  for(i = 1; i <= splitn(list "\n", a, i); i++) {
    if( Redirs[a[i]] == 0 ) {
      print "# [[:" a[i] "]]" >> G["data"] "report"
      Sweep[a[i]] = 1
    }
  }
  if(usecol) print closed >> G["data"] "report"

  print "\n== Redirects in [[:Wikipedia:Featured articles]] ==" >> G["data"] "report"
  if(usecol) print opend >> G["data"] "report"
  for(k in Redirs) {
    if(Redirs[k] != 0 && k !~ "-Hydroxy β-methylbutyric acid") {
      print "# [[:" k "]] --> [[:" Redirs[k] "]]" >> G["data"] "report"
      Sweep[k] = 1
    }
  }
  if(usecol) print closed >> G["data"] "report"

  print "\n{{ombox | text = Report generated " curtime("space") " by '''[[User:GreenC bot/Job 15|fambot]]'''.}}" >> G["data"] "report"
 
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
    if(jsona["query","pages","1","redirect"] == 1) {
      #if(namewiki ~ "Hydroxy")
      #  sendlog(G["logfile"], "isredirect() ---- " command " ---- " jsonin)
      return 1
    }
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
# Populate Redirs[] with titles in listfaa that are redirects
#
function getredirects( pos,i,a) {

  # If in Featured articles/all but not Category:Featured articles
  # Check each for redirect 
  pos = sys2var(Exe["grep"] " -vxF -f " G["data"] "listfa " G["data"] "listfaa")  
  for(i = 1; i <= splitn(pos "\n", a, i); i++) {
    if(isredirect(a[i])) 
      Redirs[a[i]] = whatisredirect(a[i])
    else
      Redirs[a[i]] = 0
  }

}

#
# Get articles in Wikipedia:Featured article candidates
#
function getlistfac(   fp,field,sep,i,result,c) {

  fp = wikiget(Exe["wikiget"] " -w " shquote("Wikipedia:Featured article candidates") )
  if(empty(fp)) 
    return ""

  # {{Wikipedia:Featured article candidates/Svalbard discography/archive1}}
  c = patsplit(fp, field, /[{]{2}Wikipedia:Featured article candidates\/[^}]*[}]{2}/, sep)
  for(i = 1; i <= c; i++) {
    if(field[i] !~ /\/archive[0-9]/) continue
    sub(/[{]{2}[ ]*Wikipedia:Featured[ _]article[ _]candidates\//, "", field[i])
    sub(/\/archive[0-9][ ]*[}]{2}$/, "", field[i])
    result = result "\n" field[i]
  }
  result = strip(result)

  if(!length(result)) {
    sendlog(G["logfile"], curtime() " ---- Empty result[] for Wikipedia:Featured_article_candiates. Breakpoint A")
    return ""
  }
 
  return result   
 
}



#
# Get articles in Wikipedia:Featured articles
#
function getlistfaa(   fp,k,i,a,spot,dest,result,command,firstsect,re,d) {

  fp = wikiget(Exe["wikiget"] " -w " shquote("Wikipedia:Featured articles") )
  if(empty(fp)) 
    return ""

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
  re = "^==[ ]*" regesc3(firstsect) "[ ]*==[ ]*$"

  for(i = 1; i <= splitn(fp, a, i); i++) {
    if(spot == 0 && a[i] ~ re) 
      spot = 1
    if(spot) {

      # * [[...]]|{{FA/...}}
      # "[[...]]|{{FA/...}}
      # ''[[...]]|{{FA/...}}
      if(a[i] ~ /^[ ]*([']{1,5}|["]|[*])?[ ]*([{]{2}FA[/]|[[]{2})/) {

        if(match(a[i], /[[]{2}[^\]|]+[^\]|]/, d) > 0) {
          sub(/^[[]{2}/, "", d[0])
          if(d[0] ~ /^Category:/) continue
          result[k++] = strip(firstCap(d[0]))
        }
      }
    }
  }

  if(!length(result)) {
    sendlog(G["logfile"], curtime() " ---- Empty result[] for Wikipedia:Featured_articles. Breakpoint B")
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
function getlists(   listwfa,listfa,listfaa) {

  # Category:Wikipedia featured articles

  listwfa = clearnl(wikiget(Exe["wikiget"] " -c " shquote("Wikipedia featured articles") ))
  #listwfa = readfile(G["data"] "listwfa")
  if(empty(listwfa)) 
    sendlog(G["logfile"], curtime() " ---- Empty fp for Category:Wikipedia_featured_articles")

  # Category:Featured articles

  listfa = clearnl(wikiget(Exe["wikiget"] " -c " shquote("Featured articles") ))
  #listfa = readfile(G["data"] "listfa")
  if(empty(listfa)) 
    sendlog(G["logfile"], curtime() " ---- Empty fp for Category:Featured_articles")

  # Category:Wikipedia featured article candidates

  listwfac = clearnl(wikiget(Exe["wikiget"] " -c " shquote("Wikipedia featured article candidates") " | " Exe["grep"] " -vE " shquote("(Wikipedia:|Template:)") ))
  if(empty(listwfac)) 
    sendlog(G["logfile"], curtime() " ---- Empty fp for Category:Wikipedia_featured_article_candidates")

  # Wikipedia:Featured article candidates

  listfac = clearnl(getlistfac())
  if(empty(listfac)) 
    sendlog(G["logfile"], curtime() " ---- Empty fp for Wikipedia:Featured_article_candidates")

  # Wikipedia:Featured articles

  listfaa = clearnl(getlistfaa())
  #listfaa = readfile(G["data"] "listfaa")
  if(empty(listfaa)) 
    sendlog(G["logfile"], curtime() " ---- Empty fp for Wikipedia:Featured_articles")

  if( countsubstring(listwfa, "\n") < 6000 || countsubstring(listfa, "\n") < 6000 || countsubstring(listfaa, "\n") < 6000) {
    sendlog(G["logfile"], curtime() " ---- List(s) too short. Program Aborted.")
    #print listwfa > G["meta"] "listwfa"
    #print listfa > G["meta"] "listfa"
    #print listfaa > G["meta"] "listfaa"
    if(countsubstring(listfaa, "\n") < 6000 && countsubstring(listfa, "\n") > 6000 && countsubstring(listfaa, "\n") > 6000) {
      print "Bot error: trouble parsing [[Wikipedia:Featured articles]] - page format changed? Please contact [[User:GreenC]]" > G["data"] "report"
      close(G["data"] "report")
      upload(readfile(G["data"] "report"), "Wikipedia:Featured articles/mismatches", "Bot error: trouble parsing [[Wikipedia:Featured articles]]", G["meta"], BotName, "en")
    }
    exit
  }

  print listwfa  > G["data"] "listwfa";  close(G["data"] "listwfa")
  print listfa   > G["data"] "listfa";   close(G["data"] "listfa")
  print listwfac > G["data"] "listwfac"; close(G["data"] "listwfac")
  print listfac  > G["data"] "listfac";  close(G["data"] "listfac")
  print listfaa  > G["data"] "listfaa";  close(G["data"] "listfaa")

}



function main(  ls) {

  delete Sweep   # number of new changes by article name
  getlists()
  getredirects()
  report()

  ls = int(length(Sweep))
  if(ls > 0) {
    if(ls < 2)
      G["summary"] = "1 page needs help (report by [[User:GreenC bot/Job 15|fambot]])"
    else
      G["summary"] = ls " pages need help (report by [[User:GreenC bot/Job 15|fambot]]"
  }
  else
    G["summary"] = "No problems detected (report by [[User:GreenC bot/Job 15|fambot]])"

  close(G["data"] "report")
  upload(readfile(G["data"] "report"), "Wikipedia:Featured articles/mismatches", G["summary"], G["meta"], BotName, "en")

}


