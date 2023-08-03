import std/[logging, strformat]
import nirc
import colored_logger

# setup logging
addHandler(newColoredLogger(levelThreshold = lvlInfo))

# setup irc client
let irc = newIRC(server = "irc.freenode.net",channel = "#testit", nickname = "rbot")
irc.connect()

# for each message, say Hello to the user
for (user, msg) in irc.recvMsg():
  irc.sendMsg(&"Hello {user}")

# disconnect after sendMsg doesn't receive anything
irc.disconnect()
