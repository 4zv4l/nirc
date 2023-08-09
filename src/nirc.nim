import std/[net, logging, strformat, strutils]
import regex

type IRC = ref object
  server, channel, nickname: string
  port: Port
  conn: Socket

proc newIRC*(server: string, port: uint32 = 6667, channel, nickname: string): IRC =
  IRC(
    server: server, port: Port(port), 
    channel: channel, nickname: nickname,
    conn: newSocket()
  )

proc send(self: IRC, msg: string) =
  self.conn.send(msg & "\n")
  debug &"Send: {msg}"

proc sendMsg*(self: IRC, text: string) =
  let msg = &"PRIVMSG {self.channel} :{text}"
  self.send(msg)

proc recv(self: IRC): string =
  result = self.conn.recvLine()
  if result == "": quit("connection closed")
  debug &"Recv: {result}"
  if result.startsWith(re"PING"):
    debug &"Recv: {result}"
    self.send(&"PONG {result.split[1][0..^1]}")

iterator recvMsg*(self: IRC): (string, string) =
  var m: RegexMatch
  while (let line = self.recv(); line != ""):
    if line.match(re &":(?P<user>.+)!.+PRIVMSG {self.channel} :(?P<msg>.+)", m):
      let (user, msg) = (m.group("user", line)[0], m.group("msg", line)[0])
      debug &"Recv: {user} PRIVMSG {self.channel} :{msg}"
      yield (user, msg)

proc connect*(self: IRC) =
  info &"Connecting to {self.server}:{self.port}"
  self.conn.connect(self.server, self.port)
  self.send(&"USER {self.nickname} {self.nickname} {self.nickname} :bot")
  self.send(&"NICK {self.nickname}")
  while not self.recv().contains("MODE"): discard
  self.send(&"JOIN {self.channel}")
  info &"Connected to {self.server}:{self.port}{self.channel}"

proc disconnect*(self: IRC) =
  self.conn.close
  info &"Disconnected from {self.server}:{self.port}"
