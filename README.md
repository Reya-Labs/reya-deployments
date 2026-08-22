# reya-deployments
- variables follow camel case
- invoke commands follow snake case


```
yarn
RPC_KEY=... yarn reya_network:test
RPC_KEY=... yarn reya_cronos:test
RPC_KEY=... yarn reya_devnet:test
```

Cannon needs `CANNON_IPFS_URL=https+ipfs://repo.usecannon.com` and a
registry settings file — see [CANNON.md](CANNON.md), which also collects the
recurring failure modes (silent step skips, registry rate limits, CREATE2
collisions between sibling clones, publishing, resuming a partial build).
