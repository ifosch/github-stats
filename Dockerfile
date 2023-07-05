FROM ruby:3-alpine

ENV APP_HOME "/home/ghs"

RUN mkdir -p ${APP_HOME} \
    && addgroup ghs \
    && adduser -h ${APP_HOME} -s /bin/bash -S -D -G ghs ghs \
    && chown ghs:ghs ${APP_HOME} \
    && chmod 0755 ${APP_HOME}

WORKDIR ${APP_HOME}

# copy gemfile separately to cache step before more frequent code changes :)
COPY Gemfile Gemfile.lock ${APP_HOME}/
RUN bundle install

ADD . ${APP_HOME}
RUN chown --recursive ghs:ghs ${APP_HOME}

USER ghs

ENTRYPOINT ["bundle","exec"]
