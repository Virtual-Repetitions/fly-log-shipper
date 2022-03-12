# NOTICE

Please note this is a fork of [fly-log-shipper](https://github.com/superfly/fly-log-shipper).

This removes support for all providers except Loki in our Vector configuration.

# fly-log-shipper

Ship logs from fly to other providers using [NATS](https://docs.nats.io/) and [Vector](https://vector.dev/)

Here we have some vector configs and a nats client (\`fly-logs\`), along side a wrapper script to run it all, that will subscribe to a log stream of your organisations logs, and ship it to various providers.

# Configuration

Create a new Fly app based on this Dockerfile and configure using the following secrets:

## fly-logs configuration

| Secret         | Description                                                                                                      |
| -------------- | ---------------------------------------------------------------------------------------------------------------- |
| `ORG`          | Organisation slug                                                                                                |
| `ACCESS_TOKEN` | Fly personal access token                                                                                        |
| `SUBJECT`        | Subject to subscribe to. See [[NATS]] below (defaults to `logs.>`)                                             |
| `QUEUE`        | Arbitrary queue name if you want to run multiple log processes for HA and avoid duplicate messages being shipped |

## Provider configuration

### Loki

| Secret          | Description   |
| --------------- | ------------- |
| `LOKI_URL`      | Loki Endpoint |
| `LOKI_USERNAME` | Loki Username |
| `LOKI_PASSWORD` | Loki Password |


# NATS

The log stream is provided through the [NATS protocol](https://docs.nats.io/nats-protocol/nats-protocol) and is limited to subscriptions to logs in your organisations. The `fly-logs` app is simply a Go NATS client that takes some Fly specific environment variables to connect to the stream, but any NATS client can connect to `fdaa::3` on port `4223` in a Fly vm, with an organisation slug as the username and a Fly Personal Access Token as the password.

The subject schema is `logs.<app_name>.<region>.<instance_id>` and the standard [NATS wildcards](https://docs.nats.io/nats-concepts/subjects#wildcards) can be used. In this app, the `SUBJECT` secret can be used to set the subject and limit the scope of the logs streamed.

If you would like to run multiple vm's for high availability, the NATS endpoint supports [subscription queues](https://docs.nats.io/nats-concepts/queue) to ensure messages are only sent to one subscriber of the named queue. The `QUEUE` secret can be set to configure a queue name for the client.

---

# Vector

The `fly-logs` application sends logs to a unix socket which is created by Vector. This processes the log lines and sends them to various providers. The config is generated from a shell wrapper script which uses conditionals on environment variables to decide which Vector sinks to configure in the final config.

# Debugging Locally

The simplest approach to debugging Vector configuration locally is to use `stdin` as the source and print to console.

```toml
[sources.in]
type = "stdin"

# Add your transforms here

[sinks.out]
inputs = ["in"]
type = "console"
encoding.codec = "json"
```

And then run this command to pipe stdin to Vector:
```
echo 'dashboard           | {"app":"dashboard","level":null,"message":"Message here","metadata":{"depth":20,"erl_level":"warning"},"severity":"warn","time":"2022-03-11T20:17:45.456Z"}' | vector --config ./vector.toml
```

To test your VRL code, check out [The VRL Playground](https://vrl-web.netlify.app/).