Generates new instances of Tor and provides a list of running instances

Example usage:

```
bash generate-tor-instances.sh -g=10 
curl --socks5 $(bash generate-tor-instances.sh -r | shuf -n1) $url

```
