@echo off

minikube start --mount --mount-string="C:/pub/setmy.info/data/minikube/gintra:/var/opt/setmy.info/gintra" --driver=docker
