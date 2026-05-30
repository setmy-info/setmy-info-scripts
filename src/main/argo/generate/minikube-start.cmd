@echo off
rem Start Minikube with the docker driver.
rem
rem The NFS server runs on the host machine (not inside the cluster).
rem After start, install nfs-common so kubelet can mount NFS volumes:
rem
rem   minikube ssh "sudo apt-get update -q && sudo apt-get install -y nfs-common"
rem
rem Verify the host NFS export is reachable (host gateway is usually 192.168.49.1):
rem   minikube ssh "showmount -e 192.168.49.1"

minikube start --driver=docker
