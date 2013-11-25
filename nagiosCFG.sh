#!/bin/bash
# Nagios Core 4.0.1 Install on Debian Wheezy
# Author: John McCarthy
# Date: November 25, 2013
#
# To God only wise, be glory through Jesus Christ forever. Amen.
# Romans 16:27, I Corinthians 15:1-4
#------------------------------------------------------
######## FUNCTIONS ########
function nagiosCore()
{
 #Add Nagios Users and Groups
  echo ''
  echo -e '\e[01;34m+++ Adding Nagios Users and Groups...\e[0m'
  echo ''
  groupadd -g 9000 nagios
  groupadd -g 9001 nagcmd
  useradd -u 9000 -g nagios -G nagcmd -d /usr/local/nagios -c 'Nagios Admin' nagios
  adduser www-data nagcmd
  echo ''
  echo -e '\e[01;37;42mThe Nagios users and groups have been successfully added!\e[0m'

 #Install Require Packages
  echo ''
  echo -e '\e[01;34m+++ Installing Prerequisite Packages...\e[0m'
  echo ''
  apt-get update
  apt-get install -y apache2 libapache2-mod-php5 build-essential libgd2-xpm-dev libssl-dev
  echo ''
  echo -e '\e[01;37;42mThe Prerequisite Packages were successfully installed!\e[0m'

 #Download latest Nagios Core Version (4.0.2)
  echo ''
  echo -e '\e[01;34m+++ Downloading the Latest Nagios Core files...\e[0m'
  echo ''
  wget http://prdownloads.sourceforge.net/sourceforge/nagios/nagios-4.0.2.tar.gz
  echo -e '\e[01;37;42mThe Nagios Core installation files were successfully downloaded!\e[0m'

 #Untarring the Nagios Core File
  echo ''
  echo -e '\e[01;34m+++ Untarrring the Nagios Core files...\e[0m'
  tar xzf nagios-4.0.2.tar.gz
  cd nagios-4.0.2
  echo ''
  echo -e '\e[01;37;42mThe Nagios Core installation files were successfully untarred!\e[0m'

 #Configure and Install Nagios Core
  echo ''
  echo -e '\e[01;34m+++ Installing Nagios Core...\e[0m'
  echo ''
  ./configure --prefix=/usr/local/nagios --with-nagios-user=nagios --with-nagios-group=nagios --with-command-user=nagios --with-command-group=nagcmd
  make all
  make install
  make install-init
  make install-config
  make install-commandmode
  make install-webconf
  echo -e '\e[01;37;42mNagios Core has been successfully installed!\e[0m'
}
function webUIpassword()
{
 #Create a user to access the Nagios Web UI
        echo -e '\e[33mChoose your Nagios Web UI Username\e[0m'
  read webUser

 # Use this command to add subsequent users later on (eliminate the '-c' switch, which creates the file)
 # htpasswd /usr/local/nagios/etc/htpasswd.users username
 # **NOTE** users will only see hots/services for which they are contacts <http://nagios.sourceforge.net/docs/nagioscore/3/en/cgiauth.html>
  htpasswd -c /usr/local/nagios/etc/htpasswd.users $webUser

 #Changes the Ownership of the htpasswd.users file
  chown nagios:nagcmd /usr/local/nagios/etc/htpasswd.users
  echo ''
        echo -e '\e[01;37;42mNagios Web UI Username and password successfully created!\e[0m'
}
function nagiosBoot()
{
  echo ''
        echo -e '\e[01;34m+++ Creating Nagios Init File...\e[0m'
        echo ''

 #Adding in the old init script, as the one included with 4.0.1 has a bug in it
 #http://stackoverflow.com/questions/19606049/nagios-4-cant-open-etc-rc-d-init-d-functions

cat << 'EOT' > /etc/init.d/nagios
#!/bin/sh
#
# chkconfig: 345 99 01
# description: Nagios network monitor
#
# File : nagios
#
# Author : Jorge Sanchez Aymar (jsanchez@lanchile.cl)
#
# Description: Starts and stops the Nagios monitor
#              used to provide network services status.
#

# Load any extra environment variables for Nagios and its plugins
if test -f /etc/sysconfig/nagios; then
 . /etc/sysconfig/nagios
fi

status_nagios ()
{

 if test -x $NagiosCGI/daemonchk.cgi; then
  if $NagiosCGI/daemonchk.cgi -l $NagiosRunFile; then
          return 0
  else
   return 1
  fi
 else
  if ps -p $NagiosPID > /dev/null 2>&1; then
          return 0
  else
   return 1
  fi
 fi

 return 1
}


printstatus_nagios()
{

 if status_nagios $1 $2; then
  echo "nagios (pid $NagiosPID) is running..."
 else
  echo "nagios is not running"
 fi
}


killproc_nagios ()
{

 kill $2 $NagiosPID

}


pid_nagios ()
{

 if test ! -f $NagiosRunFile; then
  echo "No lock file found in $NagiosRunFile"
  exit 1
 fi

 NagiosPID=`head -n 1 $NagiosRunFile`
}


# Source function library
# Solaris doesn't have an rc.d directory, so do a test first
if [ -f /etc/rc.d/init.d/functions ]; then
 . /etc/rc.d/init.d/functions
elif [ -f /etc/init.d/functions ]; then
 . /etc/init.d/functions
fi

prefix=/usr/local/nagios
exec_prefix=${prefix}
NagiosBin=${exec_prefix}/bin/nagios
NagiosCfgFile=${prefix}/etc/nagios.cfg
NagiosStatusFile=${prefix}/var/status.dat
NagiosRetentionFile=${prefix}/var/retention.dat
NagiosCommandFile=${prefix}/var/rw/nagios.cmd
NagiosVarDir=${prefix}/var
NagiosRunFile=${prefix}/var/nagios.lock
NagiosLockDir=/var/lock/subsys
NagiosLockFile=nagios
NagiosCGIDir=${exec_prefix}/sbin
NagiosUser=nagios
NagiosGroup=nagios


# Check that nagios exists.
if [ ! -f $NagiosBin ]; then
    echo "Executable file $NagiosBin not found.  Exiting."
    exit 1
fi

# Check that nagios.cfg exists.
if [ ! -f $NagiosCfgFile ]; then
    echo "Configuration file $NagiosCfgFile not found.  Exiting."
    exit 1
fi

# See how we were called.
case "$1" in

 start)
  echo -n "Starting nagios:"
  $NagiosBin -v $NagiosCfgFile > /dev/null 2>&1;
  if [ $? -eq 0 ]; then
   su - $NagiosUser -c "touch $NagiosVarDir/nagios.log $NagiosRetentionFile"
   rm -f $NagiosCommandFile
   touch $NagiosRunFile
   chown $NagiosUser:$NagiosGroup $NagiosRunFile
   $NagiosBin -d $NagiosCfgFile
   if [ -d $NagiosLockDir ]; then touch $NagiosLockDir/$NagiosLockFile; fi
   echo " done."
   exit 0
  else
   echo "CONFIG ERROR!  Start aborted.  Check your Nagios configuration."
   exit 1
  fi
  ;;

 stop)
  echo -n "Stopping nagios: "

  pid_nagios
  killproc_nagios nagios

   # now we have to wait for nagios to exit and remove its
   # own NagiosRunFile, otherwise a following "start" could
   # happen, and then the exiting nagios will remove the
   # new NagiosRunFile, allowing multiple nagios daemons
   # to (sooner or later) run - John Sellens
  #echo -n 'Waiting for nagios to exit .'
   for i in 1 2 3 4 5 6 7 8 9 10 ; do
       if status_nagios > /dev/null; then
    echo -n '.'
    sleep 1
       else
    break
       fi
   done
   if status_nagios > /dev/null; then
       echo ''
       echo 'Warning - nagios did not exit in a timely manner'
   else
       echo 'done.'
   fi

  rm -f $NagiosStatusFile $NagiosRunFile $NagiosLockDir/$NagiosLockFile $NagiosCommandFile
  ;;

 status)
  pid_nagios
  printstatus_nagios nagios
  ;;

 checkconfig)
  printf "Running configuration check..."
  $NagiosBin -v $NagiosCfgFile > /dev/null 2>&1;
  if [ $? -eq 0 ]; then
   echo " OK."
  else
   echo " CONFIG ERROR!  Check your Nagios configuration."
   exit 1
  fi
  ;;

 restart)
  printf "Running configuration check..."
  $NagiosBin -v $NagiosCfgFile > /dev/null 2>&1;
  if [ $? -eq 0 ]; then
   echo "done."
   $0 stop
   $0 start
  else
   echo " CONFIG ERROR!  Restart aborted.  Check your Nagios configuration."
   exit 1
  fi
  ;;

 reload|force-reload)
  printf "Running configuration check..."
  $NagiosBin -v $NagiosCfgFile > /dev/null 2>&1;
  if [ $? -eq 0 ]; then
   echo "done."
   if test ! -f $NagiosRunFile; then
    $0 start
   else
    pid_nagios
    if status_nagios > /dev/null; then
     printf "Reloading nagios configuration..."
     killproc_nagios nagios -HUP
     echo "done"
    else
     $0 stop
     $0 start
    fi
   fi
  else
   echo " CONFIG ERROR!  Reload aborted.  Check your Nagios configuration."
   exit 1
  fi
  ;;

 *)
  echo "Usage: nagios {start|stop|restart|reload|force-reload|status|checkconfig}"
  exit 1
  ;;

esac

# End of this script
EOT

 #Making the Nagios Init Script Executable
  chmod +x /etc/init.d/nagios
  update-rc.d nagios defaults

 #Restart the Nagios service
  service nagios restart
  echo ''
        echo -e '\e[01;37;42mNagios has been configured to start at boot time!\e[0m'
}
function nagiosPlugin()
{
 #Download the Latest Nagios Plugin Files (1.4.16)
  echo ''
        echo -e '\e[01;34m+++ Downloading the Nagios Plugin Files...\e[0m'
  echo ''
        wget https://www.nagios-plugins.org/download/nagios-plugins-1.5.tar.gz
  echo -e '\e[01;37;42mThe Latest Nagios Plugins have been acquired!\e[0m'

 #Untarring the Nagios Plugin File
  echo ''
  echo -e '\e[01;34m+++ Untarrring the Nagios Core files...\e[0m'
  tar xzf nagios-plugins-1.5.tar.gz
  cd nagios-plugins-1.5
  echo ''
  echo -e '\e[01;37;42mThe Nagios Core installation files were successfully untarred!\e[0m'

 #Configure and Install Nagios Plugins
  echo ''
  echo -e '\e[01;34m+++ Installing Nagios Plugins...\e[0m'
  echo ''
  ./configure --with-nagios-user=nagios --with-nagios-group=nagios --with-openssl=/usr/bin/openssl --enable-perl-modules --enable-libtap
  make
  make install
  echo ''
  echo -e '\e[01;37;42mThe Nagios Plugins have been successfully installed!\e[0m'
}
function nrpe()
{
 #Download latest NRPE Files (2.15)
  echo ''
  echo -e '\e[01;34m+++ Downloading the Latest NRPE files...\e[0m'
  echo ''
  wget http://sourceforge.net/projects/nagios/files/nrpe-2.x/nrpe-2.15/nrpe-2.15.tar.gz/download
  echo ''
  echo -e '\e[01;37;42mThe NRPE installation files were successfully downloaded!\e[0m'

 #Untarring the NRPE File
  echo ''
  echo -e '\e[01;34m+++ Untarrring the Nagios Core files...\e[0m'
  echo ''
  tar xzf nrpe-2.15.tar.gz
  cd nagios-4.0.1
  echo ''
  echo -e '\e[01;37;42mThe NRPE installation files were successfully untarred!\e[0m'

 #Configure and Install NRPE
 #http://askubuntu.com/questions/133184/nagios-nrpe-installation-errorconfigure-error-cannot-find-ssl-libraries
  echo ''
  echo -e '\e[01;34m+++ Installing NRPE...\e[0m'
  echo ''
  ./configure --with-ssl=/usr/bin/openssl --with-ssl-lib=/usr/lib/x86_64-linux-gnu
  make
  make install
  echo ''
  echo -e '\e[01;37;42mNRPE has been successfully installed!\e[0m'
}
function emailNotifications()
{
 #Install Require Packages
  echo ''
  echo -e '\e[01;34m+++ Installing Prerequisite Packages...\e[0m'
  echo ''
  apt-get install -y sendmail-bin sendmail heirloom-mailx
  echo ''
  echo -e '\e[01;37;42mThe Rrerequisite Packages for Nagios Notifications were successfully installed!\e[0m'
}
function webSSL()
{
 #Make Your Self-signed Certificates
 echo -e '\e[33mChoose your Certificates Name\e[0m'
 read CERT
 mkdir /etc/apache2/ssl
 cd /etc/apache2/ssl
 openssl req -x509 -nodes -days 365 -newkey rsa:4096 -keyout $CERT.key -out $CERT.crt
 a2enmod ssl

 #Configure /etc/apache2/conf.d/nagios.conf
 sed -i 's/#  SSLRequireSSL/   SSLRequireSSL/g' /etc/apache2/conf.d/nagios.conf

 #Configure /etc/apache2/sites-available/default
 echo -e '\e[33mChoose your Server Admin Email Address\e[0m'
 read EMAIL
cat <<EOF > /etc/apache2/sites-available/default
<VirtualHost *:443>
    ServerAdmin $EMAIL
    ServerName $CERT.crt
    DocumentRoot /var/www/$CERT

    <Directory />
        Options FollowSymLinks
        AllowOverride None
    </Directory>

    <Directory /var/www/$CERT>
        Options -Indexes FollowSymLinks MultiViews
        AllowOverride All
        Order allow,deny
        allow from all
    </Directory>

     SSLEngine On
     SSLCertificateFile /etc/apache2/ssl/$CERT.crt
     SSLCertificateKeyFile /etc/apache2/ssl/$CERT.key
</VirtualHost>
EOF

 #Make DirectoryRoot Directory
  mkdir /var/www/$CERT

 #Restart Your Apache2 Service
  service apache2 restart
}

#This Function is Used to Call its Corresponding Function
function doAll()
{
    #Calls Function 'nagioscore'
  echo -e "\e[33m=== Install Nagios Core ? (y/n)\e[0m"
        read yesno
        if [ "$yesno" = "y" ]; then
                nagiosCore
        fi

 #Calls Function 'webUIpassword'
        echo
        echo -e "\e[33m=== Add Nagios Web UI Password ? (y/n)\e[0m"
        read yesno
        if [ "$yesno" = "y" ]; then
                webUIpassword
        fi

 #Calls Function 'nagiosBoot'
 echo
        echo -e "\e[33m=== Start Nagios Server at Boot Time ? (y/n)\e[0m"
        read yesno
        if [ "$yesno" = "y" ]; then
                nagiosBoot
        fi

 #Calls Function 'nagiosPlugin'
        echo
        echo -e "\e[33m=== Install the Nagios Plugins ? (y/n)\e[0m"
        read yesno
        if [ "$yesno" = "y" ]; then
                nagiosPlugin
        fi

 #Calls Function 'nrpe'
        echo
        echo -e "\e[33m=== Install NRPE ? (y/n)\e[0m"
        read yesno
        if [ "$yesno" = "y" ]; then
                nrpe
        fi

 #Calls Function 'emailNotifications'
        echo
        echo -e "\e[33m=== Edit Nagios Email Notification Settings ? (y/n)\e[0m"
        read yesno
        if [ "$yesno" = "y" ]; then
                emailNotifications
        fi

 #Calls Function 'webSSL'
  echo
        echo -e "\e[33m=== Configure Nagios Web UI to use SSL (HTTPS) ? (y/n)\e[0m"
        read yesno
        if [ "$yesno" = "y" ]; then
                webSSL
        fi

 #End of Script Congratulations, Farewell and Additional Information
  FARE=$(cat << 'EOD'


          \e[01;37;42mWell done! You have completed your Nagios Core Installation!\e[0m

             \e[01;37;42mProceed to your Nagios web UI, http://fqdn/nagios\e[0m


                            \e[01;37m########################\e[0m
                            \e[01;37m#\e[0m \e[31mI Corinthians 15:1-4\e[0m \e[01;37m#\e[0m
                            \e[01;37m########################\e[0m
EOD
)

  #Calls the End of Script variable
  echo -e "$FARE"
  echo
  echo
        exit 0
}

# Check privileges
[ $(whoami) == "root" ] || die "You need to run this script as root."

# Welcome to the script
echo
echo
echo -e '              \e[01;37;42mWelcome to Midacts Mystery'\''s Nagios Core Installer!\e[0m'
echo
echo
case "$go" in
        core)
                nagiosCore ;;
        webPass)
                webUIpassword ;;
        boot)
                nagiosBoot ;;
        plugin)
                nagiosPlugin ;;
        nrpe)
                nrpe ;;
        email)
                emailNotifications ;;
        ssl)
                webSSL ;;
        * )
                        doAll ;;
esac

exit 0
