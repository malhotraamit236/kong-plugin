[![Build Status][badge-travis-image]][badge-travis-url]

Usher: Kong plugin to route requests based on HTTP Headers
================================================================

Usher is a configurable Kong plugin that routes requests to different upstreams
based on HTTP Header name-value pairs.

[badge-travis-url]: https://travis-ci.org/malhotraamit236/kong-plugin
[badge-travis-image]: https://travis-ci.org/malhotraamit236/kong-plugin.svg?branch=master

- [Usher: Kong plugin to route requests based on HTTP Headers](#usher-kong-plugin-to-route-requests-based-on-http-headers)
  - [Terminology](#terminology)
  - [Use Case - Example](#use-case---example)
  - [Configuration](#configuration)
    - [Rules](#rules)
  - [Usage Demo (macOS)](#usage-demo-macos)
    - [Setup Kong Vagrant Environment](#setup-kong-vagrant-environment)
    - [Setup Route](#setup-route)

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
This plugin has been tested by enabling on `Service` object. In that context, following paramters
can be used for configuration.
| **Parameter**  | **Description**                                         |
| -------------- | ------------------------------------------------------- |
| `name`         | The name of the plugin to use - `usher` for this plugin |
| `service.id`   | The ID of the Service the plugin targets.               |
| `config.rules` | List of rules                                           |

### Rules
`config.rules` takes a list of rules and each rule has two mandatory properties:
| **Property**    | **Description**                                                                     |
| --------------- | ----------------------------------------------------------------------------------- |
| `condition`     | Map of header name and value pairs where header name is the key                     |
| `upstream_name` | `name` of the `Upstream` object which load-balances traffic on its `Target` objects |

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
|`Route`|Custom HTTP Request Headers|Proxied to `Upstream`|
|-|-|-|
|`/local`|*no custom header*|`europe_cluster`|
|`/local`|`X-Country=Italy`|`italy_cluster`|
|`/local`|`X-Country=Italy` <br> `X-Region=Milan`|`milan_cluster`|
|`/local`|`X-Country=Italy` <br> `X-Region=Venice`|`venice_cluster`|


For the purpose of this demo we are building [`kong`](https://github.com/Kong/kong) and `usher` from source on a vagrant machine with [`kong-vagrant`](https://github.com/Kong/kong-vagrant). Also the demo uses [`HTTPie`](https://httpie.org/) but you an use `curl` as well.

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

### Setup Route
