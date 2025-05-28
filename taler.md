
```
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@localhost -p 1111

systemd-run -p DynamicUser=yes -p User=taler-exchange-httpd --wait --pty bash
systemd-run -p DynamicUser=yes -p User=taler-exchange-dbinit --wait --pty bash

systemd-run -p DynamicUser=yes -p User=taler-exchange-httpd --wait --pty taler-exchange-dbinit -c /exchange.conf -L debug
systemd-run -p DynamicUser=yes -p User=taler-exchange-httpd --wait --pty bash

taler-exchange-dbinit -c /exchange.conf -L debug

psql -U taler-exchange-httpd -f /nix/store/n3d87gal0zk640r01wnsl0j6ns9m3al8-taler-exchange-1.0.0/share/taler-exchange/sql/versioning.sql

cp /etc/taler/conf.d/taler-exchange.conf /exchange.conf
```

```
systemd-run -p DynamicUser=yes -p User=taler-merchant-httpd --wait --pty taler-merchant-dbinit -c /etc/taler/taler.conf -L debug

cat /nix/store/vgr9z87gkban3dqbnd7ir02057kyg6p6-generated-taler-merchant.conf > /tmp/merchant.conf
```

```
taler-exchange-offline download > /tmp/future-keys.json
exchange.copy_from_vm("future-keys.json", "/tmp/future-keys.json")
```

```
curl -X POST -u exchange:exchange -H 'Content-Type: application/json' --data '{"scope": "readwrite"}' -sSfL 'http://bank:8082/accounts/exchange/token'

curl -H 'Authorization: Bearer secret-token:67BFH2KB1RPYYGB0M3WBVC6Q69XWNV12B5BZ85V25VHDCZJSC3Y0' -X POST -H 'Content-Type: application/json' --data '{"amount": "KUDOS:10"}' -sSfL 'http://bank:8082/accounts/testUser/withdrawals'
```

```
curl -X POST -H 'Authorization: Bearer secret-token:R9SEWJZRCNK5G6K3QY9M9DRE3DM3BVWXDTHV67RR8MGGPNFYM930' -H 'Content-Type: application/json' --data '{"amount":"KUDOS:10"}' -sSfL 'http://bank:8082/accounts/testUser/withdrawals/1916d838-3a19-4a6c-8139-0ac46eb3312c/confirm'

curl -H 'Authorization: Bearer secret-token:HDPKXB26XG305DDV69ESJWNC77T20GMGSQHE7T8SD92GHTN27X2G' -H 'Content-Type: application/json' -sSfL 'http://bank:8082/withdrawals/54f9875c-825e-4fa7-8fbe-69d3f7108bda'

curl -H 'Authorization: Bearer secret-token:BQ3C6QHRRY3W71RJT8R1F25X5RM1SBBHPK7DGHHKK1CQK3RFM3ZG' -H 'Content-Type: application/json' --data '{"amount":"KUDOS:10"}' -sSfL 'http://bank:8082/accounts/testUser/withdrawals'

curl -X POST -H 'Authorization: Bearer secret-token:HDPKXB26XG305DDV69ESJWNC77T20GMGSQHE7T8SD92GHTN27X2G' -H 'Content-Type: application/json' --data '{"amount": "KUDOS:10"}' -sSfL 'http://bank:8082/accounts/testUser/withdrawals/54f9875c-825e-4fa7-8fbe-69d3f7108bda/confirm'

taler-wallet-cli --no-throttle api --expect-success 'withdrawTestBalance' '{ "user":"testUser", "amount": "KUDOS:8", "corebankApiBaseUrl": "http://bank:8082/", "exchangeBaseUrl": "http://exchange:8081/" }'
```

```
curl -H 'Authorization: Bearer secret-token:W3V7GMCQ27SCAV6J2V221F21JW9D1SBQWYFTBEJA7YXEVZTEBKK0' -sSfL 'http://bank:8082/withdrawals/dc5cbec1-94db-4b27-ba1e-51d177fb70f2'
```

```
systemd-run -p DynamicUser=yes -p User=taler-exchange-wirewatch --wait --pty bash
/nix/store/hg77205s5cwh04llnhl5spsj96lh0gs1-taler-exchange-1.0.0/bin/taler-exchange-wirewatch -c /nix/store/6pzb5n76pjmrfir5kdxnqzs3vmcnl2br-taler.conf -L debug
```

taler-exchange-wire-gateway-client -c /tmp/taler-accounts.conf --section exchange-accountcredentials-test --debit-history

```
curl -X POST -u default:default -H 'Content-Type: application/json' --data '{"scope": "readwrite"}' -sSfL 'http://merchant:8083/instances/default/private/token'

curl -X POST -H 'Authorization: Bearer secret-token:super_secret' -H 'Content-Type: application/json'             --data '{              "order": { "amount": "KUDOS:1", "summary": "Test Order" },              "inventory_products": [{ "product_id": "1", "quantity": 1 }]            }'             -sSfL 'http://merchant:8083/instances/default/private/orders'
```

systemd-run -p DynamicUser=yes -p User=taler-merchant-httpd --wait --pty bash
taler-merchant-exchangekeyupdate -c /nix/store/skz6zj9lsk4wxyypmi80wy9ja4va56vc-taler.conf
