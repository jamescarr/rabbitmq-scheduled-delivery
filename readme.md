# RabbitMQ Scheduled Message Delivery
Earlier this month I gave a presentation at [ComoRichWeb](http://comorichweb.posterous.com/) on [RabbitMQ](http://rabbitmq.com) and
one question from an attendee was "Is it possible to publish a message
to be consumed at a later date?" I answered that it wasn't possible to
the best of my knowledge, but that there might be some hack to
accomplish it. Well, this evening while trying to figure out how to use
a push vs. polling model for timed notifications I discovered a clever
hack using temporary queues, x-message-ttl and dead letter exchanges. 

The main idea behind this is utilizing a new feature available in 2.8.0,
<a
href="http://www.rabbitmq.com/extensions.html#dead-letter-exchanges">dead-letter
exchanges</a>. This AMQP extension allows you to specify an exchange on
a queue that messages should be published to when a message either
expires or is rejected with requeue set to false. 

With this in mind, we can simply create a queue for messages we want to
be delivered later with an x-message-ttl set to the duration we want to
wait before it is delivered. And to ensure the message is transferred to
another queue we simply define the x-dead-letter-exchange to an exchange
we created (in this case I'll call it immediate) and bind a queue to it
(the "right.now.queue"). 

In coffeescript with node-amqp this looks like this:

```coffee
amqp   = require 'amqp'
conn   = amqp.createConnection()
  
key = "send.later.#{new Date().getTime()}"
conn.on 'ready', ->
  conn.queue key, {
    arguments:{
      "x-dead-letter-exchange":"immediate"
    , "x-message-ttl": 5000
    }
  }
```

Next I define the immediate exchange, bind a queue to it and subscribe.

```coffee
 conn.exchange 'immediate'

  conn.queue 'right.now.queue', {autoDelete: false, durable: true}, (q)->
    q.bind('immediate', 'right.now.queue')
    q.subscribe (msg, headers, deliveryInfo) ->
      console.log msg
      console.log headers
```

Finally, after defining the queue I created earlier we want publish a
message on it. So to revisit the earlier queue definition we add a
publish call to publish directly to the queue (using the default
exchange). 

```coffee
conn.on 'ready', ->
  conn.queue key, {
    arguments:{
      "x-dead-letter-exchange":"immediate"
    , "x-message-ttl": 5000
    }
  }, ->
    conn.publish key, {v:1}, {contentType:'application/json'}
```


The result of running this is we'll see a 5 second wait and then the
message content and headers get dumped to the console. One gotcha I
noticed while experimenting with this is that while my send.later queue
is set to auto-delete (meaning it should delete itself after my app is
finished) it sticks around after I'm done with it. This is no doubt due
to the broker maintaining a connection to it internally so as a final
touch I also add an x-expires argument to the queue definition to ensure
that the queue will eventually go away.

[example.coffee](https://github.com/jamescarr/rabbitmq-scheduled-delivery/blob/master/example.coffee) is the result of this exercise in its entirety. 


## Running It

You'll need node.js (0.6.12 is what I am running) and coffee-script
installed. You'll also need rabbitmq running with default settings.

```bash
$ git clone git://github.com/jamescarr/rabbitmq-scheduled-delivery.git
$ cd rabbitmq-scheduled-delivery
$ npm install && coffee example

```

## Notes
The current version of node-amqp has a parse bug when handling some
message headers. This exercises uses my own patched version where I
simply swallow the exception. I'll revert to use the real node-amqp when
the issue is resolved.
