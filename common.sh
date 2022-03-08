# sh safe .sh strip from calling scriptname
caller() {
  echo $(echo "$(basename "${0}")" | sed 's/\.sh//')
}

lastrun() {
  touch /tmp/$(caller).lastrun
}

# Timestamp logs, output to file and stdout
log() {
    echo "$(date +'%d/%m/%Y %H:%M:%S') $@" | tee -a /var/log/$(caller)
}

#Silently exectute something
sExec() {
  $("$@" > /dev/null 2>&1)
}
