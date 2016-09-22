# solr-utils (LUA)
Lua scripts mainly for use within [Nginx Lua module](https://github.com/openresty/lua-nginx-module)

### solr_args.lua
**solr_args** package for proxying frontent arguments to SOLR backend
  
  **Example usage (nginx config):**

  ```
  # build $args
  set_by_lua_block $args {
        return require("solr_args")
                .reset()
                .wildcard_query(ngx.var.arg_q)
                .start(ngx.var.arg_start)
                .output_json(ngx.var.arg_o == 'json')
                .filter('arg_fy', '{!tag=YEAR}year', tonumber(ngx.var.arg_fy))
                .filter('arg_fm', '{!tag=MONTH}month', tonumber(ngx.var.arg_fm))
                .build();
  }

  # rewrite path
  rewrite ^ /solr/code1/select break;

  # proxy request
  proxy_pass http://solr6_server;
  ```


### web_args.lua
**web_args** package for building url argument string

# Installation
* Download & unpack as needed
* Specify lua package path, i.e.:
    ``lua_package_path '/www/_lib/lua/?.lua';``
