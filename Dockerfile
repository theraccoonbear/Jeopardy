from perl:latest

ADD ./ /opt/src
WORKDIR /opt/src

#RUN /opt/src/build/install-perl-modules

EXPOSE 5000

CMD /opt/src/util/run
