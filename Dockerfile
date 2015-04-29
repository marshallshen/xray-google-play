FROM ruby:2.2.0

RUN apt-get update && apt-get install -y \
    curl libfreetype6 libfontconfig bzip2

ENV PHANTOMJS_VERSION 1.9.8

RUN curl -SLO "https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-$PHANTOMJS_VERSION-linux-x86_64.tar.bz2" \
	&& tar -xjf "phantomjs-$PHANTOMJS_VERSION-linux-x86_64.tar.bz2" -C /usr/local --strip-components=1 \
	&& rm "phantomjs-$PHANTOMJS_VERSION-linux-x86_64.tar.bz2"

RUN mkdir /xray
WORKDIR /xray
ADD Gemfile /xray/Gemfile
RUN bundle install
ADD . /xray
