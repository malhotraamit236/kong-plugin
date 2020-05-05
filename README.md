[![Build Status][badge-travis-image]][badge-travis-url]

Usher: Kong plugin to route requests based on HTTP Headers
================================================================

Usher is a configurable Kong plugin that routes requests to different upstreams
based on HTTP Header name-value pairs.

[badge-travis-url]: https://travis-ci.org/malhotraamit236/kong-plugin
[badge-travis-image]: https://travis-ci.org/malhotraamit236/kong-plugin.svg?branch=master

# Table of Contents
- [Usher: Kong plugin to route requests based on HTTP Headers](#usher-kong-plugin-to-route-requests-based-on-http-headers)
- [Table of Contents](#table-of-contents)
  - [Terminology](#terminology)
  - [Use Case - Example](#use-case---example)
  - [Configuration](#configuration)
    - [Rules](#rules)
  - [Usage Demo (macOS)](#usage-demo-macos)
    - [Setup Kong Vagrant Environment](#setup-kong-vagrant-environment)
    - [Setup Upstreams with Targets](#setup-upstreams-with-targets)
    - [Setup Service](#setup-service)
    - [Setup Route](#setup-route)
    - [Enable Usher Plugin](#enable-usher-plugin)
    - [Test cases](#test-cases)

## Terminology
- `plugin`: a plugin executing actions inside Kong before or after a request has been proxied to the upstream API.
- `Service`: the Kong entity representing an external upstream API or microservice.
- `Route`: the Kong entity representing a way to map downstream requests to upstream services.
- `Upstream`: the Kong entity representing a virtual hostname and can be used to loadbalance incoming requests over multiple services (targets)
- `Target`: A target is an ip address/hostname with a port that identifies an instance of a backend service.

## Use Case - Example
Requests that match route `/local` will be proxied to `Upstream` `europe_cluster`,
except requests that contain `X-Country = Italy` will be proxied to Upstream `italy_cluster`.

## Configuration
This plugin has been tested by enabling on `Service` object and works in `access` phase. In that context, following paramters
can be used for configuration.
| **Parameter**                  | **Description**                                         |
| ------------------------------ | ------------------------------------------------------- |
| `name`                         | The name of the plugin to use - `usher` for this plugin |
| `service.id`                   | The ID of the Service the plugin targets.               |
| `config.rules`<br>*(required)* | List of rules                                           |

### Rules
`config.rules` takes a list of rules and each rule has two mandatory properties:
| **Property**                                                                                  | **Description**                                                                     |
| --------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------- |
| `condition`<br>*(required)*<br>*(duplicate header names<br> with differing case not allowed)* | Map of header name and value pairs where header name is the key                     |
| `upstream_name`<br>*(required)*                                                               | `name` of the `Upstream` object which load-balances traffic on its `Target` objects |

The header name-value pairs given in a `condition` are evaluated with a logical AND. 
The rule with a `condition` that has maximum ANDed header name-value match wins and request is proxied to
the `Upstream` specified by `upstream_name`.

If more than one rule evalutes to true, then the one that appears earliest in the `config.rules` wins. 
For example, given a config like: 
```
config = {
  "rules": [
    {
      "condition": {
        "X-Country": "Italy"
      }
      "upstream_name": "italy_cluster"
    },
    {
      "condition": {
        "X-Region": "Milan"
      }
      "upstream_name": "milan_cluster"
    }
  ]
}
```
If request headers contain `"X-Country": "Italy"` and `"X-Region": "Milan"` then request will be proxied to `italy_cluster`.

## Usage Demo (macOS)
We are going to demo following scenario:
| `Route`  | Custom HTTP Request Headers              | Proxied to `Upstream` |
| -------- | ---------------------------------------- | --------------------- |
| `/local` | *no custom header*                       | `europe_cluster`      |
| `/local` | `X-Country=Italy`                        | `italy_cluster`       |
| `/local` | `X-Country=Italy` <br> `X-Region=Milan`  | `milan_cluster`       |
| `/local` | `X-Country=Italy` <br> `X-Region=Venice` | `venice_cluster`      |


For the purpose of this demo we are building [`kong`](https://github.com/Kong/kong) and `usher` from source on a vagrant machine with [`kong-vagrant`](https://github.com/Kong/kong-vagrant). Also the demo uses [`HTTPie`](https://httpie.org/) but you an use `curl` as well.

[![asciicast](https://asciinema.org/a/mJz2tOP5K7Li5JBtDsXQWauAi.svg)](https://asciinema.org/a/mJz2tOP5K7Li5JBtDsXQWauAi)

### Setup Kong Vagrant Environment
- Download and Install [Vagrant](https://www.vagrantup.com/downloads.html) if not already installed. To check if it is already installed, try `vagrant version` in terminal.
- Setup environment:
  ```shell
  # clone this repository
  $ git clone https://github.com/Kong/kong-vagrant
  $ cd kong-vagrant

  # clone the Kong repo (inside the vagrant one)
  $ git clone https://github.com/Kong/kong

  # clone usher plugin
  $ git clone https://github.com/malhotraamit236/kong-plugin.git

  # build a box with a folder synced to your local Kong and plugin sources
  $ vagrant up

  # ssh into the Vagrant machine, and setup the dev environment
  $ vagrant ssh
  $ cd /kong
  $ make dev

  # build usher
  $ cd /kong-plugin
  $ luarocks make

  # tell Kong to load usher plugin
  $ export KONG_PLUGINS=bundled,usher
  # if you are running Kong < 0.14.0, run this instead:
  # $ export KONG_CUSTOM_PLUGINS=usher

  # startup kong: while inside '/kong' call `kong` from the repo as `bin/kong`!
  # we will also need to ensure that migrations are up to date
  $ cd /kong
  $ bin/kong migrations bootstrap
  # if you are running Kong < 0.15.0, run this instead of bootstrap:
  # $ bin/kong migrations up
  $ bin/kong start
  ```
- Open a new terminal window and `cd` into `kong-vagrant` repo directory created in the step before.
- Check if `kong` has started. 
  ```shell 
  $ http :8001
  ``` 
  Admin api root should output `kong` configuration if kong has sucessfully started.

### Setup Upstreams with Targets
- Add `Upstream` `europe_cluster` with target `mockbin.org:80`
  ```shell
  $ http POST :8001/upstreams name=europe_cluster
  $ http POST :8001/upstreams/europe_cluster/targets target=mockbin.org:80
  ```
- Add `Upstream` `italy_cluster` with target `httpbin.org:80`
  ```shell
  $ http POST :8001/upstreams name=italy_cluster
  $ http POST :8001/upstreams/italy_cluster/targets target=httpbin.org:80
  ```
- Add `Upstream` `milan_cluster` with target `requestbin.com:80`
  ```shell
  $ http POST :8001/upstreams name=milan_cluster
  $ http POST :8001/upstreams/milan_cluster/targets target=requestbin.com:80
  ```
- Add `Upstream` `venice_cluster` with target `postb.in:80`
  ```shell
  $ http POST :8001/upstreams name=venice_cluster
  $ http POST :8001/upstreams/venice_cluster/targets target=postb.in:80
  ```
### Setup Service
Add a `Service` `name=example_service` with `host=europe_cluster`
```shell 
$ http :8001/services name=example_service host=europe_cluster
```

### Setup Route
Add a `Route` to `example_service` with `name=localroute` and a path `/local`.
```shell 
$ http :8001/services/example_service/routes name=localroute paths:='["/local"]'
```

### Enable Usher Plugin
Let's enable `usher` on `example_service` for our scenario.
```shell
$ http POST :8001/services/example_service/plugins \
    name=usher \
    config:='{"rules":[{"condition":{"X-Country":"Italy"},"upstream_name":"italy_cluster"},{"condition":{"X-Country":"Italy","X-Region":"Milan"},"upstream_name":"milan_cluster"},{"condition":{"X-Country":"Italy","X-Region":"Venice"},"upstream_name":"venice_cluster"}]}'
```
The config looks like this:
```
{
   "rules":[
      {
         "condition":{
            "X-Country":"Italy"
         },
         "upstream_name":"italy_cluster"
      },
      {
         "condition":{
            "X-Country":"Italy",
            "X-Region":"Milan"
         },
         "upstream_name":"milan_cluster"
      },
      {
         "condition":{
            "X-Country":"Italy",
            "X-Region":"Venice"
         },
         "upstream_name":"venice_cluster"
      }
   ]
}
```
### Test cases
1. No custom header
    | `Route`  | Custom HTTP Request Headers | Proxied to `Upstream` | Response from Target |
    | -------- | --------------------------- | --------------------- | -------------------- |
    | `/local` | *no custom header*          | `europe_cluster`      | mockbin.org          |
    ```shell 
    $ http :8000/local

    HTTP/1.1 200 OK
    Connection: keep-alive
    Content-Encoding: gzip
    Content-Type: text/html; charset=utf-8
    Date: Tue, 05 May 2020 18:14:22 GMT
    Etag: W/"29c7-XG+PICJmz/J+UYWt5gkKqqAUXjc"
    Kong-Cloud-Request-ID: d03ebc07ef2f0fa78d1cf5fa86f35011
    Server: Cowboy
    Transfer-Encoding: chunked
    Vary: Accept-Encoding
    Via: kong/2.0.4
    X-Kong-Proxy-Latency: 0
    X-Kong-Upstream-Latency: 115
    X-Kong-Upstream-Status: 200

    <!DOCTYPE html><html><head><meta charset="utf-8"><title>Mockbin by Kong</title>
    
    ...
    ```
2. With `X-Country=Italy`
    | `Route`  | Custom HTTP Request Headers | Proxied to `Upstream` | Response from Target |
    | -------- | --------------------------- | --------------------- | -------------------- |
    | `/local` | `X-Country=Italy`           | `italy_cluster`       | httpbin.org          |
    ```shell 
    $ http GET :8000/local X-Country:Italy
    
    HTTP/1.1 200 OK
    Access-Control-Allow-Credentials: true
    Access-Control-Allow-Origin: *
    Connection: keep-alive
    Content-Length: 9593
    Content-Type: text/html; charset=utf-8
    Date: Tue, 05 May 2020 18:21:56 GMT
    Server: gunicorn/19.9.0
    Via: kong/2.0.4
    X-Kong-Proxy-Latency: 1
    X-Kong-Upstream-Latency: 91

    ...

    <a href="https://github.com/requests/httpbin" class="github-corner" aria-label="View source on Github">
    
    ...
    ```
3. With `X-Country=Italy` and `X-Region=Milan`
    | `Route`  | Custom HTTP Request Headers             | Proxied to `Upstream` | Response from Target |
    | -------- | --------------------------------------- | --------------------- | -------------------- |
    | `/local` | `X-Country=Italy` <br> `X-Region=Milan` | `milan_cluster`       | requestbin.com       |
    ```shell 
    $ http GET :8000/local X-Country:Italy X-Region:Milan
    
    HTTP/1.1 301 Moved Permanently
    Connection: keep-alive
    Content-Length: 183
    Content-Type: text/html
    Date: Tue, 05 May 2020 18:28:16 GMT
    Location: https://requestbin.com/
    Server: CloudFront
    Via: kong/2.0.4
    X-Amz-Cf-Id: sEMftS-6ZcalP4XfDG_WHJ7yel50j4_VzxI-V9E8cxGTtrDE4UsPBA==
    X-Amz-Cf-Pop: YTO50-C1
    X-Cache: Redirect from cloudfront
    X-Kong-Proxy-Latency: 1
    X-Kong-Upstream-Latency: 36

    <html>
    <head><title>301 Moved Permanently</title></head>
    <body bgcolor="white">
    <center><h1>301 Moved Permanently</h1></center>
    <hr><center>CloudFront</center>
    </body>
    </html>

    ...
    ```
4. With `X-Country=Italy` and `X-Region=Venice`
    | `Route`  | Custom HTTP Request Headers              | Proxied to `Upstream` | Response from Target |
    | -------- | ---------------------------------------- | --------------------- | -------------------- |
    | `/local` | `X-Country=Italy` <br> `X-Region=Venice` | `venice_cluster`      | postb.in             |
    ```shell 
    $ http GET :8000/local X-Country:Italy X-Region:Venice
    
    HTTP/1.1 301 Moved Permanently
    Connection: keep-alive
    Content-Length: 194
    Content-Type: text/html
    Date: Tue, 05 May 2020 18:31:11 GMT
    Location: https://postb.in/
    Server: nginx/1.10.3 (Ubuntu)
    Via: kong/2.0.4
    X-Kong-Proxy-Latency: 0
    X-Kong-Upstream-Latency: 87

    <html>
    <head><title>301 Moved Permanently</title></head>
    <body bgcolor="white">
    <center><h1>301 Moved Permanently</h1></center>
    <hr><center>nginx/1.10.3 (Ubuntu)</center>
    </body>
    </html>

    ...
    ```
5. With `X-Country=Italy` and `X-Region=Venice` and `X-Region=Milan`. This is a special scenario where
    duplicate header names appear in a Request. In this case the header that appears last in the
    request is considered for matching.
    | `Route`  | Custom HTTP Request Headers                                   | Proxied to `Upstream` | Response from Target |
    | -------- | ------------------------------------------------------------- | --------------------- | -------------------- |
    | `/local` | `X-Country=Italy` <br> `X-Region=Venice`<br> `X-Region=Milan` | `milan_cluster`      | requestbin.com       |
    ```shell 
    $ http GET :8000/local X-Country:Italy X-Region:Venice X-Region:Milan
    
    HTTP/1.1 301 Moved Permanently
    Connection: keep-alive
    Content-Length: 183
    Content-Type: text/html
    Date: Tue, 05 May 2020 22:20:07 GMT
    Location: https://requestbin.com/
    Server: CloudFront
    Via: kong/2.0.4
    X-Amz-Cf-Id: pDX-LQWU0Lk3E080BCb3_rVvlyNOxmhSAgayswcv9vwuyjHtHdZVbg==
    X-Amz-Cf-Pop: YTO50-C1
    X-Cache: Redirect from cloudfront
    X-Kong-Proxy-Latency: 0
    X-Kong-Upstream-Latency: 34

    <html>
    <head><title>301 Moved Permanently</title></head>
    <body bgcolor="white">
    <center><h1>301 Moved Permanently</h1></center>
    <hr><center>CloudFront</center>
    </body>

    ...
    ```