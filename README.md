WikiMismatchReports
===========
* fambot - Featured articles Mismatch Bot
* gambot - Good articles Mismatch Bot
* flmbot - Featured lists Mismatch Bot

Three bots that monitor various pages and categories on Enwiki and report when there is a problem with the configurations for Featured and Good articles

Install
==========

* Clone the repo

        cd ~
        git clone 'https://github.com/greencardamom/WikiMismatchReports'

* Install BotWikiAwk library

        cd ~ 
        git clone 'https://github.com/greencardamom/BotWikiAwk'
        export AWKPATH=.:/home/user/BotWikiAwk/lib:/usr/share/awk
        export PATH=$PATH:/home/user/BotWikiAwk/bin
	add above AWKPATH and PATH to your shell's login script eg. .bashrc
        cd ~/BotWikiAwk
        ./setup.sh
        read SETUP for further instructions eg. setting up email

* Configure wikiget.awk which was installed with BotWikiAwk - add Oauth Consumer Secrets so you can post to Wikipedia. See the file "EDITSETUP" at https://github.com/greencardamom/Wikiget

* Edit fambot.awk, gambot.awk and flmbot.awk and change the home directory

Running
==========
Run the bots from cron on a regular schedule

Dependencies
====
* GNU awk 4.1+
* BotWikiAwk library
* Bot account with bot perms to post to Wikipedia, and Oauth Consumer credentials

Credits
==================
by User:GreenC (en.wikipedia.org)

MIT License Copyright 2024
