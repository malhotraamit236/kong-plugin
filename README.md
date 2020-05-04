[![Build Status][badge-travis-image]][badge-travis-url]

Kong plugin template
====================

This repository contains a very simple Kong plugin template to get you
up and running quickly for developing your own plugins.

This template was designed to work with the
[`kong-pongo`](https://github.com/Kong/kong-pongo) and
[`kong-vagrant`](https://github.com/Kong/kong-vagrant) development environments.

Please check out those repos `README` files for usage instructions.

[badge-travis-url]: https://travis-ci.org/Kong/kong-plugin/branches
[badge-travis-image]: https://travis-ci.com/Kong/kong-plugin.svg?branch=master

http POST :8001/services/example_service/plugins \
  name=usher \
  config:='{"rules":[{"condition": {"X-Country":"Italy"}, "upstream_name":"italy_cluster"},{"condition": {"X-Country":"Italy", "X-Region":"Milan"}, "upstream_name":"milan_cluster"},{"condition": {"X-Country":"Italy", "X-Region":"Venice"}, "upstream_name":"venice_cluster"}]}'

explain this:
if num_of_given_header_keys ~= num_of_case_insensitive_header_keys then
    return nil, "Duplicate headers with different case found in condition: " ..  pl_pretty_write(condition)
  elseif num_of_given_header_keys < 1 then
    return nil, "Empty condition" ..  pl_pretty_write(condition)
  end