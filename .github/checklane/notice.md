> [!NOTE]
> This is [Checklane](https://checklane.sh)’s fork of [shivammathur/setup-php](https://github.com/shivammathur/setup-php). It changes one thing: `use_builds_cache: true` works on Checklane runners the way it does on Blacksmith and Depot runners, so setup-php installs PHP from the prebuilt builds it uses on GitHub’s own Ubuntu runners. Everything else is upstream, synced every day.
>
> ```yaml
> - uses: checklane/setup-php@v2
>   with:
>     php-version: '8.4'
>   env:
>     use_builds_cache: true
> ```
>
> `v2` follows upstream’s `v2` release. Upstream releases from `2.40.0` on are also tagged here under their version, for pinning. Once setup-php supports Checklane runners itself, switch back to `shivammathur/setup-php@v2`.
