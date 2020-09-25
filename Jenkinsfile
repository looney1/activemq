#!/groovy

properties([[$class: 'GitLabConnectionProperty', gitLabConnection: 'GitLab']])

serviceName = 'activemq'
branchName = env['BRANCH_NAME']
envName = buildUtilities.getEnvironmentName(branchName)

buildUtilities.initVars(branchName, 'NA')

buildsList = ['setup', 'version check', 'build']
if(branchName == 'master') {
    buildsList.add('deploy')
}

serviceStartDelay = 180 // seconds 
serviceRetryDelay = 30  // seconds
serviceRetryCount = 15


node {
	gitlabBuilds(builds: buildsList) {
	    stage('setup') {
	      gitlabCommitStatus(name: 'setup') {
	        buildUtilities.setup()
	      }
	    }
	    stage('version check') {
	      gitlabCommitStatus(name: 'version check') {
	        buildUtilities.versionCheck(getCodeVersion())
	      }
	    }
		stage('build'){
			gitlabCommitStatus(name: 'build') {
	            docker.withRegistry(buildUtilities.dockerRepoURI, 'docker-repo-login') {
	                def dockerImage = docker.build('activemq')
	                def taggedImageName = dockerImage.tag(getProjectVersion())
	                sh "docker push ${taggedImageName}"
	                sh "docker rmi -f ${taggedImageName}"
	            }
			}
		}
		
        if (branchName.startsWith('dv') || branchName == 'master') {
            stage('automated-tests') {
                gitlabCommitStatus(name: 'automated-tests') {
                    buildUtilities.deployToEnvironment(envName, serviceName, branchName, getProjectVersion())
                    if (buildUtilities.ensureDeploymentIsReady(envName, serviceName, getProjectVersion(), serviceStartDelay, serviceRetryDelay, serviceRetryCount)) {
                        runAutomatedTests(envName)
                    }
                    else {
                        sh "exit 1;"
                    }
                }

            }
        }

    	if(branchName == 'master')
    	{
    		stage('deploy') {
    			gitlabCommitStatus(name: 'deploy') {
					buildUtilities.deployToAllDevEnvironments(serviceName, branchName, getProjectVersion())
                    buildUtilities.tagGitRepo(getProjectVersion())
    			}
    		}
    	}
	}
}

String getCodeVersion() {
    def versionProps = readProperties(text: readTrusted('image.properties'))
    return versionProps['version']
}

String getProjectVersion() {
    def projectVersion = getCodeVersion()
    if (branchName != 'master') {
        projectVersion += "-${buildUtilities.getGitCommit().take(12)}"
    }
    return projectVersion
}

String runAutomatedTests() {
    print "No Automated Tests at this time."
}    
def runAutomatedTests(String envName) {
    String nodePort = buildUtilities.getNodePort(envName, serviceName)
    print "No Automated Tests at this time, service running on ${nodePort}"
}