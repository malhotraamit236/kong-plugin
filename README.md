[![Build Status][badge-travis-image]][badge-travis-url]
[badge-travis-url]: https://travis-ci.org/malhotraamit236/kong-plugin
[badge-travis-image]: https://travis-ci.org/malhotraamit236/kong-plugin.svg?branch=master

Usher: Kong plugin to route requests based on HTTP Headers
================================================================

Usher is a configurable Kong plugin that routes requests to different upstreams
based on HTTP Header key-value pairs.

- [Usher: Kong plugin to route requests based on HTTP Headers](#usher-kong-plugin-to-route-requests-based-on-http-headers)
  - [Terminology](#terminology)
  - [Example Use Case](#example-use-case)
  - [Configuration](#configuration)

## Terminology
- `plugin`: a plugin executing actions inside Kong before or after a request has been proxied to the upstream API.
- `Service`: the Kong entity representing an external upstream API or microservice.
- `Route`: the Kong entity representing a way to map downstream requests to upstream services.
- `Upstream`: the Kong entity representing a virtual hostname and can be used to loadbalance incoming requests over multiple services (targets)
- `Target`: A target is an ip address/hostname with a port that identifies an instance of a backend service.

## Example Use Case
Requests that match route `/local` will be proxied to `Upstream` `europe_cluster`,
except requests that contain X-Country = Italy will be proxied to Upstream `italy_cluster`.

## Configuration
This plugin has been tested by enabling on `Service` object. In that context, following paramters
can be used for configration.
| **Parameter**  | **Description**                                         |
| -------------- | ------------------------------------------------------- |
| `name`         | The name of the plugin to use - `usher` for this plugin |
| `service.id`   | The ID of the Service the plugin targets.               |
| `config.rules` | List of rules                                           |





http POST :8001/services/example_service/plugins \
  name=usher \
  config:='{"rules":[{"condition": {"X-Country":"Italy"}, "upstream_name":"italy_cluster"},{"condition": {"X-Country":"Italy", "X-Region":"Milan"}, "upstream_name":"milan_cluster"},{"condition": {"X-Country":"Italy", "X-Region":"Venice"}, "upstream_name":"venice_cluster"}]}'

explain this:
if num_of_given_header_keys ~= num_of_case_insensitive_header_keys then
    return nil, "Duplicate headers with different case found in condition: " ..  pl_pretty_write(condition)
  elseif num_of_given_header_keys < 1 then
    return nil, "Empty condition" ..  pl_pretty_write(condition)
  end