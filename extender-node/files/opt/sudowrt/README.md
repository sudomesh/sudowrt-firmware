
These are files used by the script /etc/config/uci-defaults/99_wireless 

Extender nodes do not undergo any per-node configuration after flashing, but different types of nodes need different /etc/config/network and /etc/config/wireless scripts depending on their frequencies, number of antennas, number of ethernet interfaces and whether they have an integrated switch. The script /etc/config/uci-defaults/99_wireless detects these differences and copies the correct config files from this directory into /etc/config
         
Note: If an uci-defaults script returns 0 then it is deleted. If it returns something else then it will be run again on next boot.