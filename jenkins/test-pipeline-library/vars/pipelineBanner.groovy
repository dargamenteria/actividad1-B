#!/usr/bin/env groovy
def call() {
  script {
    sh ('''
      echo "Hostname: $(hostname -f)"
      echo "Hostinfo: $(uname -a)"
    ''')
  }
}
