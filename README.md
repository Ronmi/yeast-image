# Yeast

Yeast is a dedicated reverse proxy powered by Nginx with simple management UI.

When developping complicated web application/service, you may have a bunch of microservices running in docker containers in your PC. You might need to maintain a list of hostname/ip list or create a reverse proxy on hand for those containers to work. You may also need to create several copies of a microservice for testing purpose, and switch between them. You will find the **switch** process, normally modifying `/etc/hosts` or nginx settings, is painful. Things will be even worst when a new version released: You have to recreate containers to apply new microservice images, which means `--link` will be invalid, and ip of container might change.

A better way is using `docker network`: create a custom network, create and attach microservice containers to the network with `--net`, and place a reverse proxy before your microservices. But switch between different versions of a microservice is still painful: You have to modify settings of the reverse proxy and reload it.

Yeast provides simple web ui helping you do the **switch** job. It dynamically generates nginx setting file, and sends `reload` signal to nginx reverse proxy.

## Getting start

You have to create a custom docker network, and connect all microservice containers with it.

Here use mysql, phpmyadmin and wordpress to simulate three microservices, so you can just copy-and-paste to your terminal/browser to try yeast.

```sh
# create custom network
docker network create mynet

# create and start your microservices, but unlike in production environment, don't expose 80 port
docker run -d --net mynet --name mysql -e MYSQL_ROOT_PASSWORD=my-secret mysql
docker run -d --net mynet --name pma -e PMA_HOST=mysql phpmyadmin/phpmyadmin
docker run -d --net mynet --name wp -e WORDPRESS_DB_HOST=mysql -e WORDPRESS_DB_USER=root -e WORDPRESS_DB_PASSWORD=my-secret wordpress
```

Then create yeast container in the network, so it can connect to your microservices with container name (s1/s2/s3 above).

```sh
# don't forget to expose 80 and 8080 port!
docker run -d --net mynet --name yeast -p 80:80 -p 127.0.0.1:8080:8080 ronmi/yeast # expose 8080 only to localhost
```

Browse to http://127.0.0.1:8080 and add two mapping entries: (don't forget to add an entry for `example.com` in `/etc/hosts`)

* Map `http://127.0.0.1/pma/` to phpmyadmin
  - Server name: leave empty
  - Path: `/pma/` (note about the slashes, it is nginx syntax)
  - Upstream: `http://pma/` (again, this is nginx syntax, read nginx documentation for detail)
  - Custom tags: leave empty
* Map `http://example.com/` to wordpress, and increase max request body size so yout can use upload function of wordpress.
  - Server name: `example.com`
  - Path: `/`
  - Upstream: `http://wp`
  - Custom tags: `client_max_body_size 250m;`

Now you can try http://127.0.0.1/pma/ and http://example.com/ in your browser.

## Tags

Yeast is built on top of nginx in Debian stretch, and Debian provides three variants of nginx, each have different prebuilt modules

- [light](https://packages.debian.org/stretch/nginx-light): minimal set of features and modules
- [full](https://packages.debian.org/stretch/nginx-full): the complete set of standard modules
- [extras](https://packages.debian.org/stretch/nginx-extras): standard modules, plus extra features and modules such as the Perl module

Default tag (latest) is pointed to light.
