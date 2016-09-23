# ddnsc
simple dyndns client

this simple client, started by cron regularly, checks your IP at *urlIP* and if it changed will do a request of *urlDdns* with your *hostname*, *user* and *password* coded to update your dydns. additionally, every *force* period it will force the update.
