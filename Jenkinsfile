@Library('test-pipeline-library')_


pipeline {
  agent { label 'linux' }
  environment {
    GIT_TOKEN=credentials ('dargamenteria_github_token')
  }
  stages {
    stage('Pipeline Info') {
      steps {
        sh ('echo "        pipelineBanner "')
        pipelineBanner()
      }
    }

    stage('Get code') {
      agent { label 'linux' }
      steps {
        catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
          pipelineBanner()
          sh ('''
            [ -e "$WORKSPACE/gitCode" ] && rm -fr "$WORKSPACE/gitCode"
            git clone https://${GIT_TOKEN}@github.com/dargamenteria/actividad1-B $WORKSPACE/gitCode
            '''
          )
          stash  (name: 'workspace')
        }
      }
    }

    stage ('Analysis phase'){
      parallel {
        stage('Static code Analysis') {
          agent { label 'linux' }
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              pipelineBanner()
              unstash 'workspace'
              sh ('''
                cd "$WORKSPACE/gitCode"
                flake8 --format=pylint --exit-zero --max-line-length 120 $(pwd)/app >$(pwd)/flake8.out
                '''
              )
              recordIssues tools: [flake8(name: 'Flake8', pattern: 'gitCode/flake8.out')],
                qualityGates: [
                  [threshold: 8, type: 'TOTAL', critically: 'UNSTABLE'], 
                  [threshold: 10,  type: 'TOTAL', critically: 'FAILURE', unstable: false ]
                ]
              stash  (name: 'workspace')
            }
          }
        }
        stage('Security Analysis') {
          agent { label 'linux' }
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              pipelineBanner()
              unstash 'workspace'
              sh ('''
                cd "$WORKSPACE/gitCode"
                bandit  -r . --format custom --msg-template     "{abspath}:{line}: {test_id}[bandit]: {severity}: {msg}"  -o $(pwd)/bandit.out || echo "Controlled exit" 
                '''
              )
              recordIssues tools: [pyLint(pattern: 'gitCode/bandit.out')],
                qualityGates: [
                  [threshold: 1, type: 'TOTAL', critically: 'UNSTABLE'], 
                  [threshold: 2, type: 'TOTAL', critically: 'FAILURE', unstable: false]
                ]
              stash  (name: 'workspace')
            }
          }
        }

        stage('Coberture Analysis') {
          agent { label 'linux' }
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              pipelineBanner()
              unstash 'workspace'
              sh ('''
                cd "$WORKSPACE/gitCode"
                python3-coverage run --source=$(pwd)/app --omit=$(pwd)app/__init__.py,$(pwd)app/api.py  -m pytest test/unit/
                python3-coverage xml -o $(pwd)/coverage.xml
                '''
              )
              cobertura coberturaReportFile: 'gitCode/coverage.xml'
              stash  (name: 'workspace')
            }
          }
        }
      }
    }
  
    stage('Test phase') {
      parallel {
        stage ('Test: Unitary') {
          agent { label 'linux' }
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              pipelineBanner()
              unstash 'workspace'
              sh ('''
                echo "Test phase" 
                cd "$WORKSPACE/gitCode"
                export PYTHONPATH=.
                pytest-3 --junitxml=result-test.xml $(pwd)/test/unit
                '''
              )
            }
          }
        }

        stage ('Test: Integration') {
          agent { label 'linux' }
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              pipelineBanner()
              unstash 'workspace'
              lock ('test-resources'){
                sh ('''
                  echo "Test phase" 
                  cd "$WORKSPACE/gitCode"

                  export PYTHONPATH=.
                  export FLASK_APP=$(pwd)/app/api.py

                  flask run -h 0.0.0.0 -p 5000 &
                  java -jar /apps/wiremock/wiremock-standalone-3.5.4.jar --port 9090 --root-dir $(pwd)/test/wiremock &

                  while [ "$(ss -lnt | grep -E "9090|5000" | wc -l)" != "2" ] ; do echo "No perative yet" ; sleep 1; done

                  pytest-3 --junitxml=result-rest.xml $(pwd)/test/rest
                  '''
                )
              }
            }
          }
        }
      }
    }
    stage('Perfomance checks') {
      steps {
            pipelineBanner()
            unstash 'workspace'

            sh ('''
                echo "Test phase" 
                cd "$WORKSPACE/gitCode"

                export PYTHONPATH=.
                export FLASK_APP=$(pwd)/app/api.py

                flask run -h 0.0.0.0 -p 5000 &
                while [ "$(ss -lnt | grep -E "5000" | wc -l)" != "1" ] ; do echo "No perative yet" ; sleep 1; done
                
                scp $(pwd)/test/jmeter/flaskplan.jmx jenkins@slave2.paranoidworld.es:
                ssh jenkins@slave2.paranoidworld.es 'rm ~/flaskplan.jtl; /apps/jmeter/bin/jmeter -n -t ~/flaskplan.jmx -l ~/flaskplan.jtl'
                scp jenkins@slave2.paranoidworld.es:flaskplan.jtl .

              ''')
            perfReport sourceDataFiles: 'gitCode/flaskplan.jtl'

      }
    }

  }   
}
