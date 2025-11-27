# SOFE3200U-Project Group 7

**IMPORTANT**

Make sure to chmod +x (make executable) all of the .sh files so they are able to be executed.

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

----------------------------------------------------------

Example Output:

```bash
Enter Command (h for help): h
Commands:
e = exit
c = collect once
p = print logs
d = delete logs
a = check logs for anomalies
cl = clear screen
sc = start cron
xc = stop cron
Enter Command (h for help): p
Which log?
1) CPU
2) Memory
3) Disk
4) Network
5) All
6) Application errors (syslog)
> 5
--- CPU ---
2025-11-27 18:57:36 CPU: 0.7%

--- MEMORY ---
2025-11-27 18:57:36 MEM: 31.66%

--- DISK ---
2025-11-27 18:57:36 DISK: 56%

--- NETWORK ---
2025-11-27 18:57:36 NET iface:enp3s0 rx:0 tx:0
Enter Command (h for help): 
```
