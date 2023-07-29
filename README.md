# ddwrt_tools

Scripts that I have created to be used on a dd-wrt router.

| Name | Description |
|------|-------------|
| ddns.sh | Performs DDNS to afraid.com, Designed to be run from a samba mount on a dd-wrt router (see [Samba Filesystem](https://wiki.dd-wrt.com/wiki/index.php/Samba_Filesystem))|
| dhcp_option61.sh | Performs [Option 61 DHCP logins](https://www.skyuser.co.uk/forum/sky-broadband-help/61898-help-own-router-setup-sky-q-2.html#post472370), which is the authentication mechanism used by Now TV and Sky on their routers. Designed to be run from a samba mount on a dd-wrt router (see [Samba Filesystem](https://wiki.dd-wrt.com/wiki/index.php/Samba_Filesystem))|
| custom_script.sh | This is a concatenated script that subsumes `ddns.sh` and all sourced functions and variables found in `common.sh` and `.credentials` so that it can be installed as a 'Custom Script' under Administration -> Commands on a dd-wrt router. This removes the dependency on an external Samba share.|