@Library('test-pipeline-library')_


pipeline {
  agent { label 'agent2' }
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
      agent { label 'agent2' }
      steps {
        pipelineBanner()
        sh ('''
          [ -e "$WORKSPACE/actividad1-B" ] && rm -fr "$WORKSPACE/actividad1-B"
          git clone https://${GIT_TOKEN}@github.com/dargamenteria/actividad1-B
          '''
        )
        stash  (name: 'workspace')
      }
    }

    stage('Static code Analysis') {
      agent { label 'agent2' }
      steps {
        pipelineBanner()
        sh ('''
          cd "$WORKSPACE/actividad1-B"
          flake8 --format=pylint --exit-zero --max-line-length 120 $(pwd)/app >flake8.out
          '''
        )
        recordIssues tools: [flake8(name: 'Flake8', pattern: 'flake8.out')],
          qualityGates: [
            [threshold: 8, type: 'TOTAL', critically: 'UNSTABLE'], 
            [threshold: 10,  type: 'TOTAL', critically: 'FAILURE', unstable: false ]
          ]
        stash  (name: 'workspace')
      }
    }
    stage('Security Analysis') {
      agent { label 'agent2' }
      steps {
        pipelineBanner()
        sh ('''
          cd "$WORKSPACE/actividad1-B"
          bandit  -r . --format custom --msg-template     "{abspath}:{line}: {test_id}[bandit]: {severity}: {msg}"  -o $(pwd)/bandit.out || echo "Controlled exit" 
          '''
        )
        recordIssues tools: [pyLint(pattern: 'bandit.out')],
          qualityGates: [
            [threshold: 1, type: 'TOTAL', critically: 'UNSTABLE'], 
            [threshold: 2, type: 'TOTAL', critically: 'FAILURE', unstable: false]
          ]
        stash  (name: 'workspace')
      }
    }

    stage('Coberture Analysis') {
      agent { label 'agent2' }
      steps {
        pipelineBanner()
        sh ('''
          cd "$WORKSPACE/actividad1-B"
          python3-coverage run --source=$(pwd)/app --omit=$(pwd)app/__init__.py,$(pwd)app/api.py  -m pytest test/unit/
          python3-coverage xml -o $(pwd)/coverage.xml
          '''
        )
        cobertura coberturaReportFile: '$WORKSPACE/coverage.xml'
        stash  (name: 'workspace')
      }
    }


    stage('Test phase') {
      parallel {
        stage ('Test: Unitary') {
          agent { label 'agent1' }
          steps {
            pipelineBanner()
            catchError(buildResult: 'SUCCESS', stageResult: 'SUCCESS') {
              unstash 'workspace'
              sh ('''
                echo "Test phase" 
                cd "$WORKSPACE/actividad1-B"
                export PYTHONPATH=.
                pytest-3 --junitxml=result-test.xml $(pwd)/test/unit
                ''')
            }
          }
        }

        stage ('Test: Rest') {
          agent { label 'agent1' }
          steps {
            pipelineBanner()
            catchError(buildResult: 'SUCCESS', stageResult: 'SUCCESS') {
              unstash 'workspace'
              lock ('test-resources'){
                sh ('''
                  echo "Test phase" 
                  cd "$WORKSPACE/actividad1-B"

                  export PYTHONPATH=.
                  export FLASK_APP=$(pwd)/app/api.py

                  flask run &
                  java -jar /apps/wiremock/wiremock-standalone-3.5.4.jar --port 9090 --root-dir $(pwd)/test/wiremock &

                  while [ "$(ss -lnt | grep -E "9090|5000" | wc -l)" != "2" ] ; do echo "No perative yet" ; sleep 1; done

                  pytest-3 --junitxml=result-rest.xml $(pwd)/test/rest
                  ''')
              }
            }
          }
        }
      }
    }   
  }
}


