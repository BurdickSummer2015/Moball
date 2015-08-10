#Copies $2 to the board with ip_settings designated by $1
# Argument 1 ($1): The path to ip_settings
# Argument 2 ($2): The file you want to copy over
. $1; scp ./$2 root@${BoardStaticIP}:/home/. 
