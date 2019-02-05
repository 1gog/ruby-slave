#!/bin/bash

# fix nss_wrapper
export NSS_WRAPPER_PASSWD=/tmp/passwd
export NSS_WRAPPER_GROUP=/tmp/group

# step 1
# Set current user in nss_wrapper
USER_ID=$(id -u)
GROUP_ID=$(id -g)

if [ x"$USER_ID" != x"0" ]; then

    echo "default:x:${USER_ID}:${GROUP_ID}:Jenkins Slave:${HOME}:/sbin/nologin" >> /etc/passwd
fi

# step 2
CONTAINER_MEMORY_IN_BYTES=$(cat /sys/fs/cgroup/memory/memory.limit_in_bytes)
CONTAINER_MEMORY_IN_MB=$((CONTAINER_MEMORY_IN_BYTES/2**20))

export HOME=/home/jenkins
export JENKINS_HOME=${HOME}
export JAR="${HOME}/agent.jar"
if [ ! -e ${HOME}/agent.jar ]; then
	curl -o ${HOME}/agent.jar --cacert /run/secrets/kubernetes.io/serviceaccount/ca.crt \
	${JENKINS_URL}/jnlpJars/agent.jar
fi

if [ ! -z ${JENKINS_SECRET} ] && [ ! -z ${JENKINS_TUNNEL} ]; then
	echo "Running in JNLP Slave"
	TUNNEL="-tunnel ${JENKINS_TUNNEL}"

	if [[ ! -z "${JENKINS_URL}" ]]; then
		URL="-url ${JENKINS_URL}"
	fi
	exec java ${JAVA_OPTS} -cp ${JAR} hudson.remoting.jnlp.Main -headless $TUNNEL $URL -jar-cache ${HOME} -workDir ${JENKINS_HOME} ${JENKINS_SECRET} ${JENKINS_NAME}
fi
