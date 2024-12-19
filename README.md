# Run Litd

Notes and helper scripts for setting up and running a Litd node.

## Contents

1. [Instructions](https://github.com/HannahMR/run-litd/#instructions)
2. [Server Requirements](https://github.com/HannahMR/run-litd/#server-requirements)
3. [Server Prep](https://github.com/HannahMR/run-litd/#server-prep) 
4. [Bitcoind Setup](https://github.com/HannahMR/run-litd/#bitcoind-setup)
5. [Litd Setup](https://github.com/HannahMR/run-litd/#litd-setup)



## Instructions

This guide contains checklists, example files, and helper scripts for getting a Litd node up and running on a ubuntu server. There are three major sections to the guide, server prep, bitcoind setup, and litd setup. In each of these sections you will find a description of what needs to happen, a check list to follow, links to example files, and, if you prefer, bash scripts that will run through the checklists for you! 

## Server Requirements



## Server Prep


### Server Prep Helper Script

You will need to add your team's keys ssh pubkeys to the script on line 17. 

Don't forget to make executable before trying to run it. 

```$ chmod +x server_setup.sh``` 

The script should be run with sudo. Don't worry, repo's, files, etc. will be owned by your current user(a new user called ubuntu if the server_setup script was used).

```$ sudo ./server_setup.sh```



## Bitcoind Setup


### Bitcoind Setup Helper Script

Don't forget to make executable before trying to run it. 

```$ chmod +x bitcoind_setup.sh``` 

The script should be run with sudo. Don't worry, repo's, files, etc. will be owned by your current user(a new user called ubuntu if the server_setup script was used).

```$ sudo ./bitcoind_setup.sh```



## Litd Setup


### Bitcoind Setup Helper Script

Don't forget to make executable before trying to run it. 

```$ chmod +x litd_setup.sh``` 

The script should be run with sudo. Don't worry, repo's, files, etc. will be owned by your current user(a new user called ubuntu if the server_setup script was used).

```$ sudo ./litd_setup.sh```












