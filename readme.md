# RabbitMQ Scheduled Message Delivery
A spike of an idea I've had of using message-ttl and
x-dead-letter-exchange to schedule messages to be delivered at a later
date/time.

## Running It

 * Clone this repo
 * run npm install from the project dir
 * run coffee example

## Notes
The current version of node-amqp has a parse bug when handling some
message headers. This exercises uses my own patched version where I
simply swallow the exception. I'll revert to use the real node-amqp when
the issue is resolved.
