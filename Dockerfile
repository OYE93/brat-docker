# start from a base ubuntu image
FROM ubuntu
MAINTAINER Cass Johnston <cassjohnston@gmail.com>
LABEL Modifier = "En OUYANG (enouyang@tongji.edu.cn)"

# set users cfg file
ARG USERS_CFG=users.json

# Install pre-reqs
# reference: https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
RUN apt-get update && apt-get install -y \
curl \
vim \
sudo \
wget \
rsync \
apache2 \
python \
supervisor \
&& rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Fetch  brat
RUN mkdir /var/www/brat
RUN curl http://weaver.nlplab.org/~brat/releases/brat-v1.3_Crunchy_Frog.tar.gz > /var/www/brat/brat-v1.3_Crunchy_Frog.tar.gz 
RUN cd /var/www/brat && tar -xvzf brat-v1.3_Crunchy_Frog.tar.gz

# create a symlink so users can mount their data volume at /bratdata rather than the full path
RUN mkdir /bratdata && mkdir /bratcfg
# change the ownership of /bratdata and /bratcfg
RUN chown -R www-data:www-data /bratdata /bratcfg 
RUN chmod o-rwx /bratdata /bratcfg
# create a symbolic link (also known as a symlink or soft link) using ln
RUN ln -s /bratdata /var/www/brat/brat-v1.3_Crunchy_Frog/data
# RUN ln -s /bratcfg /var/www/brat/brat-v1.3_Crunchy_Frog/cfg
# change to project configurations
RUN ln -s /bratcfg /var/www/brat/brat-v1.3_Crunchy_Frog/configurations

# And make that location a volume
VOLUME /bratdata
VOLUME /bratcfg

ADD brat_install_wrapper.sh /usr/bin/brat_install_wrapper.sh
RUN chmod +x /usr/bin/brat_install_wrapper.sh

# Make sure apache can access it
RUN chown -R www-data:www-data /var/www/brat/brat-v1.3_Crunchy_Frog/

ADD 000-default.conf /etc/apache2/sites-available/000-default.conf

# add the user patching script
# ADD user_patch.py /var/www/brat/brat-v1.3_Crunchy_Frog/user_patch.py

# Enable cgi
# a2enmod is a script that enables the specified module within the apache2 configuration
RUN a2enmod cgi

EXPOSE 80

# We can't use apachectl as an entrypoint because it starts apache and then exits, taking your container with it. 
# Instead, use supervisor to monitor the apache process
RUN mkdir -p /var/log/supervisor

ADD supervisord.conf /etc/supervisor/conf.d/supervisord.conf 

CMD ["/usr/bin/supervisord"]





