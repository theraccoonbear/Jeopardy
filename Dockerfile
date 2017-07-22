from perl:latest

ADD ./ /opt/src
WORKDIR /opt/src

RUN /opt/src/build/bake-modules

EXPOSE 5000

CMD /opt/src/build/run
