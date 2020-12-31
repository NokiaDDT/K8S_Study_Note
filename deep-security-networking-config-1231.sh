# These are test variables
# CONFIG_ORIGIN='interfaces'
# CONFIG_BAK='interfaces.bak'
# CONFIG_FAIL='interfaces.fail'

# These are real variables
CONFIG_ORIGIN='/etc/network/interfaces'
CONFIG_BAK='/etc/network/interfaces.bak'
CONFIG_FAIL='/etc/network/interfaces.fail'

# echo $CONFIG_ORIGIN
# echo $CONFIG_BAK
# echo $CONFIG_FAIL

# Run when restart networking fail
# 1. Backup fail config
# 2. Restore original config
# 3. Restart networking
config_networking_fail() {
	echo 'Restart networking fail, restore interfaces ...'
	cp -f $CONFIG_ORIGIN $CONFIG_FAIL
	mv -f $CONFIG_BAK $CONFIG_ORIGIN
	/etc/init.d/networking restart
	echo 'Please check /etc/network/interfaces.fail to understand more ...'
}

# Run when restart networking success
# 1. ping [tp-deep-v01] 5 times
# 2. Press Y|y to clean backup config
config_networking_success() {
	echo 'Start validating networking, please make sure the server [tp-deep-v01] could be resolved.'
	ping -c 5 tp-deep-v01
	echo ''
	echo ''
	read -p 'If server [tp-deep-v01] could be resolved, press y to remove backup file.' answer
	case $answer in 
    Y | y) 
        rm -rf $CONFIG_BAK;; 
    N | n) 
        echo "Ok, good bye";; 
    *) 
        echo "Ok, good bye";; 
    esac
}


clear
echo 'Start setting DNS NameServer & DNS Search process ...'
echo 'Steps:'
echo '      1. Backup original networking config'
echo '      2. Compose new networking config'
echo '      3. Restart networking'
echo '      3-1. If restart networking fail, do restore process, you can check file [/etc/networking/interface.fail] to reslove error.'
echo '      3-2. If restart networking success, it will ping MIS server [tp-deep-v01] 5 times to make sure all config is correct.'
read -p 'Press anykey to continue ...'

echo ''
echo 'Step 1:'
echo 'Backup /etc/network/interfaces to /etc/network/interfaces.bak.'
cp -f $CONFIG_ORIGIN $CONFIG_BAK

echo ''
echo 'Step 2:'
echo 'Append MIS DNS Name Servers ...'
# Clean config
echo '' > $CONFIG_ORIGIN
# Copy all lines exclude [dns-nameserver ...] to config
sed -n '/^dns-nameservers.*/!p' $CONFIG_BAK >> $CONFIG_ORIGIN
# Append MIS DNS Server IP to config
sed -e '/^dns-nameservers/!d' -e '/172.22.44.53/!s/$/ 172.22.44.53/' -e '/172.22.44.54/!s/$/ 172.22.44.54/' $CONFIG_BAK >> $CONFIG_ORIGIN
# Check dns-search exist or not, if not, append to end of file
grep -q '^dns-search corpnet.asus 172.22.44.53 172.22.44.54' $CONFIG_ORIGIN && echo 'dns-search already setted' || echo 'dns-search corpnet.asus 172.22.44.53 172.22.44.54' >> $CONFIG_ORIGIN
echo 'Rewrite /etc/network/interfaces done.'

echo ''
echo 'Step 3: Restart networking'
read -p 'Press any key to continue ... '
/etc/init.d/networking restart && config_networking_success || config_networking_fail