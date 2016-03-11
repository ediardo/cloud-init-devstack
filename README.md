This script creates some repetitive tasks for you, like:
* Creates a linux user 
* Installs base packages for your Ubuntu VM
* Installs git-review, creates ssh keys and basic config to start contributing upstream
* Install Devstack

You can use this script with cloud-init or executing the script yourself.

If you are using cloud-init: make sure to modify the variables at the beggining of the script

If you are executing the script from command-line (./stackr.sh) then you can pass the options
using named parameters. To learn more about the script usage do this:
 
```
# ./stackr.sh -h

Usage: ./stackr.sh [OPTIONS]

--user=user                 Linux user
--gerrit-username=username  Gerrit username
--gerrit-email=email        Gerrit email address
--gerrit-fullname=fullname  Your Full name (Use double quotes if spaces between names)
--with-devstack             Install devstack (default is yes)
--devstack-path=path        Devstack installation path (default is /opt/devstak)

```


Authors:

Originally developed by Szymon Wróblewski (http://pastebin.com/nVxss5H0) and extended functionality by Eddie Ramirez (https://github.com/ediardo/cloud-init-devstack)


