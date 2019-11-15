## OYE added
This docker image is for serving brat via a full web server using Apache.
As the official website said:  
> For security reasons, we strongly recommend serving brat via a full web server 
such as Apache in production environments.

### Changes
1. Not create volume like the author do (especially for Mac/OS X), instead use **a folder in the Host**  
**Reason: **if use `docker volume create` to create a volume, you have to use 
`docker volume inspect` to show the local storage in your PC, like the following:  
```bash
[
    {
        "CreatedAt": "2019-11-14T03:24:19Z",
        "Driver": "local",
        "Labels": {},
        "Mountpoint": "/var/lib/docker/volumes/brat_data/_data",
        "Name": "brat_data",
        "Options": {},
        "Scope": "local"
    }
]
```
you think the data is stored in `/var/lib/docker/volumes/brat_data/_data`?    **NO!**  
reference to <https://stackoverflow.com/questions/38532483/where-is-var-lib-docker-on-mac-os-x>, 
this folder just resides on the Docker host VM (the Alpine Linux ran by xhyve). You can run 
```bash
screen ~/Library/Containers/com.docker.docker/Data/vms/0/tty
```
then, press `Enter` to connect the Mac VM, and you can reach the data in `/var/lib/docker/volumes/brat_data/_data`  
Now, you can use `copy` to copy the data to this folder.  
Some commands you may need during the process:  
- disconnect that session but leave it open in background
```bash
Ctrl-a d
```
- list that session that's still running in background
```bash
screen -ls
```
- reconnect to that session (don't open a new one, that won't work and 2nd tty will give you garbled screen)
```
screen -r
```
- kill this session (window) and exit
```
Ctrl-a k
```


**NOTE:** 
If you want to use a local folder, and you are using docker in `OS X`, you should 
configure shared paths from `Docker -> Preferences... -> File Sharing`, add the full
path of the folder you want to mount, and when you run the image, you should set 
`-v $FULL_PATH:VOLUME_IN_CONTAINER:consistent`, see it in [Run](https://github.com/OYE93/brat-docker#run)

```bash
docker: Error response from daemon: Mounts denied: 
The paths /brat_cfg and /brat_data
are not shared from OS X and are not known to Docker.
You can configure shared paths from Docker -> Preferences... -> File Sharing.
```

2. Not use `brat_cfg` for user configuration, because we only use one user, which can be set
when run the image, change `brat_crf` to store project configuration.
- modify `Dockerfile`, add `line 36`, comment `line 51`
- modify `brat_install_wrapper.sh`, don't run `user_patch.py`

3. Add image [Build](https://github.com/OYE93/brat-docker#build)

4. Change image [Run](https://github.com/OYE93/brat-docker#run)

## NOTE
I am no longer doing anything with brat and am not maintaining this at all. 

## brat docker
This is a docker container deploying an instance of [brat](http://brat.nlplab.org/).


### Preparation
There are two ways to create the mounted folder:
1. You will need two volumes to pass annotation data and user configuration to the container. 
Start by creating a named volume for each of them like this:
```bash
docker volume create --name brat_data
docker volume create --name brat_cfg
```

2. You can create two folder pass annotation data and user configuration to the container.
```bash
mkdir brat_data
mkdir brat_cfg
```


The folder `brat_data` should be linked to your annotation data, the folder `brat_cfg`
should be linked to your annotation project configurations.
~~and the `brat-cfg` should contain a file called `users.json`.
To add multiple users to the server use `users.json` to list your users and their passwords like so:~~

```javascript
{
    "user1": "password",
    "user2": "password",
    ...
}
```

The data in these directories will persist even after stopping or removing the container.
You can then start another brat container as above and you should see the same data. 
Note that if you are using `docker < 1.9.0` named volumes are not available and 
you'll have to use a data-only container and `--volumes-from` instead.

You can also add data and edit the users from within the container. 
To add some data directly inside the container do something like:
``` bash
$ docker run --name=brat-tmp -it -v brat_data:/bratdata cassj/brat /bin/bash
$ cd /bratdata
$ wget http://my.url/some-dataset.tgz
$ tar -xvzf some-dataset.tgz
$ exit  
$ docker rm brat-tmp
```

Or, if you have data on the host machine, you can just copy the data into there from your host.

### Build
Build a brat image named `brat:v0.1`
```bash
docker build -t brat:v0.1 .
```

### Run
To run the container you need to specify a username, password and email address for BRAT as environment variables 
when you start the container. This user will have editor permissions.  
According to [Preparation](https://github.com/OYE93/brat-docker#preparation), there are two ways to create mounted
folder, so there are also two ways to run the image:
1. run:
```bash
docker run --name=brat -d -p 80:80 -v brat_data:/bratdata -v brat_cfg:/bratcfg -e BRAT_USERNAME=brat -e BRAT_PASSWORD=brat -e BRAT_EMAIL=brat@example.com brat:v0.1
```
2. Firstly, configure the shared paths from `Docker -> Preferences... -> File Sharing`, add the full
path of the folder you want to mount, then run:  
```bash
docker run --name=brat -d -p 80:80 -v $FULL_PATH_OF_brat_data:/bratdata -v $FULL_PATH_OF_brat_cfg:/bratcfg -e BRAT_USERNAME=brat -e BRAT_PASSWORD=brat -e BRAT_EMAIL=brat@example.com brat:v0.1
``` 