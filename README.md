# Ingress Controller

# <img src=".repo/assets/icon-512x512.png"  width="52" height="52"> TrivialSec

[![pipeline status](https://gitlab.com/trivialsec/ingress-controller/badges/main/pipeline.svg)](https://gitlab.com/trivialsec/ingress-controller/commits/main)

# Getting Started

1. Consider using zsh with dotenv plugin, otherwise you need to run `source .in` every time you want to use this project. So ensure the `.in` script runs before continuing
2. `make gencerts`; this will create a root certificate in `.development` directory if `BUILD_ENV` was set to "development" in step 1
3. `make build-ingress`; ads teh root CA certificate to the docker environment and prepares nginx
4. `make up`; for "development" the certbot container will just exit, the ingress container should first generate TLS certificates for each service (defined in `conf/certbot/domains-development.txt`) then direct requests to the correct container.

# Troubleshoot

Logs: `docker-compose logs -f`



## Unable to load CA Private Key

Error message: **Can't open /tmp/rootCA.pem for reading, No such file or directory**

This occurs when the ingress container entrypoint script cannot access the root CA certificate that was created using `make gencerts` because it will actually delete it's own copy of the root CA cert on purpose before nginx starts serving requests.

To solve this error, simply run `make build-ingress` and then `make up` again

## File not found /etc/letsencrypt/ssl-dhparams.pem

This occurs when your docker volume "letsencrypt-datadir" has been deleted. This volume is shared between both certbot and ingress containers and container this file (along with any Let's encrypt certificates issued).

To solve this problem all you need to do is to build and then run certbot before running ingress again. i.e. `make build-certbot` and then `make up` again

## File not found /etc/letsencrypt/options-ssl-nginx.conf

Same as "ssl-dhparams.pem" above, with the same solution

## nginx host not found in upstream

Example: nginx: [emerg] host not found in upstream "website" in /etc/nginx/conf.d/assets.conf:40

This occurs when you try to run nginx in the ingress container before you have the upstream service running, the the example case the website project is not running so you should go to that project and run the website container and then come back to start the ingress container.
