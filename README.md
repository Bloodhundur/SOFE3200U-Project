# SOFE3200U-Project

**IMPORTANT**

Ensure postfix and mail is installed and running on your terminal.

`sudo apt update`

`sudo apt install postfix`

`sudo apt install postfix mailutils`

----------------------------------------------------------

Open /etc/postfix/main.cf and set key parameters:

`myhostname = yourserver.example.com`

`myorigin = /etc/mailname`

`mydestination = localhost`

`relayhost =`

`inet_interfaces = all`

`inet_protocols = ipv4`

----------------------------------------------------------

`sudo systemctl start postfix`

`sudo systemctl enable postfix`

`sudo systemctl status postfix`

----------------------------------------------------------

To run, go to project root directory and enter this command:

`./run.sh`
