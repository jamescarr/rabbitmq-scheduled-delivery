amqp   = require 'amqp'
events = require 'events'
em     = new events.EventEmitter()
conn   = amqp.createConnection()
  
key = "send.later.#{new Date().getTime()}"
conn.on 'ready', ->
  conn.queue key, {
    arguments:{
      "x-dead-letter-exchange":"immediate"
    , "x-message-ttl": 5000
    , "x-expires": 6000
    }
  }, ->
    conn.publish key, {v:1}, {contentType:'application/json'}
  
  conn.exchange 'immediate'

  conn.queue 'right.now.queue', {
      autoDelete: false
    , durable: true
  }, (q) ->
    q.bind('immediate', 'right.now.queue')
    q.subscribe (msg, headers, deliveryInfo) ->
      console.log msg
      console.log headers


