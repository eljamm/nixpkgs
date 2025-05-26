
```
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@localhost -p 1111

systemd-run -p DynamicUser=yes -p User=taler-exchange-httpd --wait --pty bash
systemd-run -p DynamicUser=yes -p User=taler-exchange-dbinit --wait --pty bash

systemd-run -p DynamicUser=yes -p User=taler-exchange-httpd --wait --pty taler-exchange-dbinit -c /exchange.conf -L debug

taler-exchange-dbinit -c /exchange.conf -L debug

psql -U taler-exchange-httpd -f /nix/store/n3d87gal0zk640r01wnsl0j6ns9m3al8-taler-exchange-1.0.0/share/taler-exchange/sql/versioning.sql

cp /etc/taler/conf.d/taler-exchange.conf /exchange.conf
```

```
systemd-run -p DynamicUser=yes -p User=taler-merchant-httpd --wait --pty taler-merchant-dbinit -c /etc/taler/taler.conf -L debug

cat /nix/store/vgr9z87gkban3dqbnd7ir02057kyg6p6-generated-taler-merchant.conf > /tmp/merchant.conf
```
