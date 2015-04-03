#!/bin/bash

source ~/.env

echo ALEXA_HOME
echo $ALEXA_HOME

cd $ALEXA_HOME
bundle exec ruby app.rb &
bundle exec ruby watir-login.rb &
