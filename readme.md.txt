Working command to conatiner creation and backup
docker run -d -p 8080:8080 -v /jen-container:/var/jenkins_home -u root jenkins:latest