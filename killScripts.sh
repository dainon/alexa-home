ps -ef | grep "watir-login" | awk '{print $2}' | xargs kill
ps -ef | grep "ruby app.rb" | awk '{print $2}' | xargs kill
pkill firefox
