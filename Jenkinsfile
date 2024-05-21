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
          ls -arlt 
          echo $WORKSPACE
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
          flake8 --format=pylint --exit-zero app >flake8.out
          '''
        )
        recordIssues tools: [flake8(name: 'Flake8', pattern: 'flake8.out')], qualityGates: [[threshold: 10, type: 'TOTAL', unstable: true], [threshold: 11, type: 'TOTAL', unstable: false]]
        stash  (name: 'workspace')

      }
    }



    stage('Test phase') {
      parallel {
        stage ('Test: Unitary') {
          agent { label 'agent1' }
          steps {
            pipelineBanner()
            unstash 'workspace'
            sh ('''
              echo "Test phase" 
              cd "$WORKSPACE/actividad1-B"
              export PYTHONPATH=.
              pytest-3 --junitxml=result-test.xml $(pwd)/test/unit
              ''')
          }
        }

        stage ('Test: Rest') {
          agent { label 'agent1' }
          steps {
            pipelineBanner()
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

    stage ('Result Test'){
      agent { label 'agent1' }
      steps {
        pipelineBanner()
        catchError(buildResult: 'SUCCESS', stageResult: 'SUCCESS') {
          unstash 'workspace'
          sh ('''
            echo $(pwd)
            sleep 10
            ls -arlt  "$(pwd)/actividad1-B/result-test.xml"

            ''')
          junit allowEmptyResults: true, testResults: '$(pwd)/actividad1-B/result-*.xml'  
        }
      }
    }
  }
}


