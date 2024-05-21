#!/usr/bin/env groovy
def call() {
  script {
    sh ('''
      [ -d ${WORKSPACE} ] && echo "rm -fr ${WORKSPACE}/" || echo "No existe ${WORKSPACE}"
    ''')
  }
}
      

