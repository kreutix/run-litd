# Run Litd

Notes and helper scripts for setting up and running a Litd node.

Important!: These examples and scripts are designed to help developers get set up quickly to begin testing and application development. Please do not trust these files on your production build.  

## Contents

1. [Instructions](https://github.com/HannahMR/run-litd/#instructions)
2. [Server Requirements](https://github.com/HannahMR/run-litd/#server-requirements)
3. [Server Prep](https://github.com/HannahMR/run-litd/#server-prep) 
4. [Bitcoind Setup](https://github.com/HannahMR/run-litd/#bitcoind-setup)
5. [Litd Setup](https://github.com/HannahMR/run-litd/#litd-setup)



## Instructions

This guide contains checklists, example files, and helper scripts for getting a Litd node up and running on a ubuntu server. There are three major sections to the guide, server prep, bitcoind setup, and litd setup. In each of these sections you will find a description of what needs to happen, a check list to follow, links to example files, and, if you prefer, bash scripts that will run through the checklists for you! 

The current verions of these checklists and scripts installs...

- bitcoind v27.2
- litd v0.13.6-alpha

## Server Requirements

This setup is well tested on Ubuntu servers with at least the below level of resources:

- 2+ CPU Cores
- 80GB+ Storage
- 4GB+ RAM

You will need to increase these resources when running a production server or when running a full node. 

When running a full node on mainnet the server should have at least 800GB. It is common to use an attached disk for the full Blockchain. When doing that you'll need to mount the disk and then add a line to your bitcoin.conf file. 

```datadir=/path/to/the/storage/directory```

When running a pruned node the below line should be uncommented in the bitcoin.conf file. 

```prune=80000 # Prune to 80GB``` 


## Server Prep

This step prepares the server. A new ubuntu user with sudo access is created. SSH keys are added. security is tightened by disabling root login and password login.

This step can be done by following along with the checklist file found at [/checklists/server-setup-checklist.txt](https://github.com/HannahMR/run-litd/blob/main/checklists/server-setup-checklist.txt) or by running the setup bash script at [/scripts/server_setup.sh](https://github.com/HannahMR/run-litd/blob/main/scripts/server_setup.sh) 

### Server Prep Helper Script

You will need to add your team's keys ssh pubkeys to the script on line 17. 

Don't forget to make executable before trying to run it. 

```$ chmod +x server_setup.sh``` 

The script should be run with sudo. Don't worry, repo's, files, etc. will be owned by your current user(a new user called ubuntu if the server_setup script was used).

```$ sudo ./server_setup.sh```



## Bitcoind Setup

This step installs and runs bitcoind. The server is brought up to date, bitcoind dependancies are installed, the repo is cloned and bitcoind is built, a config file is created, a systemd .service file is created and bitcoind is run. 

This step can be done by following along with the checklist file found at [/checklists/bitcoind-setup-checklist.txt](https://github.com/HannahMR/run-litd/blob/main/checklists/bitcoind-setup-checklist.txt) or by running the setup bash script at [/scripts/bitcoind_setup.sh](https://github.com/HannahMR/run-litd/blob/main/scripts/bitcoind_setup.sh) 

### Bitcoind Setup Helper Script

Please double check the default values included in the config file in the script, lines 107-160, before running the script. Values such as network, passwords, etc will be selected/generated when the scritp runs. 

You will want to run this script as the new users that was created in the server setup process.

This script defaults to running a pruned node set to 50GB. If you would like to run a full node or storge the blockchain data on an attached disk, you will need to edit the script accordingly. 

This script runs checks to see what's been done as it goes, and so should be safe to run multiple times in case any run has been interupted. 

If you originally cloned this repo to /root you may want to move it to /home/ubuntu and change the owner for easier running. 

Don't forget to make executable before trying to run it. 

```$ chmod +x bitcoind_setup.sh``` 

The script should be run with sudo. Don't worry, repo's, files, etc. will be owned by your current user, a new user called ubuntu if the server_setup script was used).

```$ sudo ./bitcoind_setup.sh```



## Litd Setup

This step installs and runs litd. GoLang and NodeJS are installed, the repo is cloned and litd is built, a lit.conf file is generated, an LND wallet is created, the password saved, and the config set to auto unlock at startup, a systemd .service file is created, and litd is started!

This step can be done by following along with the checklist file found at [/checklists/litd-setup-checklist.txt](https://github.com/HannahMR/run-litd/blob/main/checklists/litd-setup-checklist.txt) or by running the setup bash scripts at [/scripts/litd_setup.sh](https://github.com/HannahMR/run-litd/blob/main/scripts/litd_setup.sh) and [/scripts/litd_setup2.sh](https://github.com/HannahMR/run-litd/blob/main/scripts/litd_setup2.sh) 

### Litd Setup Helper Script

This script runs checks to see what's been done as it goes, and so should be safe to run multiple times in case any run has been interupted. 

There are three scripts to be run here, litd_setup.sh, litd_setup2.sh and then litd_setup3.sh. You'll need to run the first script and then end the current bash session and start a new one before running the second. You will need to walk through the wallet creation process after running script two and before script three.

Don't forget to make executable before trying to run them.

```$ chmod +x litd_setup.sh``` 
```$ chmod +x litd_setup2.sh```
```$ chmod +x litd_setup3.sh```

The scripts should be run with sudo. Don't worry, repo's, files, etc. will be owned by your current user, a new user called ubuntu if the server_setup script was used).

```$ sudo ./litd_setup.sh```
```$ sudo ./litd_setup2.sh```
```$ sudo ./litd_setup3.sh```

Happy Building! 


