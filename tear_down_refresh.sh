#!/bin/bash

#===========================================================================================
# Set up 
#===========================================================================================
#[ "$1" == "" ] && { echo Provide namespace; exit 1; }
NAMESPACE="connectors01-nft-g1dr"

#===========================================================================================
# Functions 
#===========================================================================================

function delete_dags {
  echo "create delete_dags.sh ..."
	DAG_DELETE_SCRIPT='for dag in $(cat /tmp/dags.txt); do echo "deleting dag $dag"; airflow delete_dag --yes $dag; done'
	echo $DAG_DELETE_SCRIPT > delete_dags.sh
	chmod +x delete_dags.sh

  echo "get scheduler pod ..."
	SCHEDULER_POD=$(kubectl get pods -n $NAMESPACE | grep scheduler | awk '{print $1}')
  [ "${SCHEDULER_POD}" == "" ] && { echo "Unable to find the schduler pod, return from function ..."; return 1; }
  echo "ssh to scheduler pod and list dags to file ..."
	[ "${SCHEDULER_POD}" != "" ] && kubectl exec -it $SCHEDULER_POD -n $NAMESPACE -- bash -c "airflow list_dags 2>&1 | grep PERF_TEST > /tmp/dags.txt"
  echo "ssh to scheduler pod and delete dag files from dags directory..."
	[ "${SCHEDULER_POD}" != "" ] && kubectl exec -it $SCHEDULER_POD -n $NAMESPACE -- bash -c "rm dags/*.py"
  echo "delete dags ..."
	[ "${SCHEDULER_POD}" != "" ] && kubectl cp delete_dags.sh ${SCHEDULER_POD}:/tmp -n $NAMESPACE && \
	kubectl exec -it $SCHEDULER_POD -n $NAMESPACE -- bash -c "/tmp/delete_dags.sh 2>&1 | egrep -iv 'DeprecationWarning|INFO|ELASTICSEARCH'"
}

function scale_to_zero {
	echo "Getting workers deployment ... " && WORKER_DEPLOYMENT=$(kubectl get deploy -n $NAMESPACE | grep airflow-airflow-worker | awk '{print $1}')
	echo "Getting webserver deployment ... " && WEBSERVER_DEPLOYMENT=$(kubectl get deploy -n $NAMESPACE | grep airflow-airflow-webserver | awk '{print $1}')
	echo "Getting scheduler deployment ... " && SCHEDULER_DEPLOYMENT=$(kubectl get deploy -n $NAMESPACE | grep airflow-airflow-scheduler | awk '{print $1}')
	echo "Getting worker deployment to zero ... " && kubectl scale deployment --replicas 0 $WORKER_DEPLOYMENT -n $NAMESPACE
	echo "Getting webserver deployment to zero ... " && kubectl scale deployment --replicas 0 $WEBSERVER_DEPLOYMENT -n $NAMESPACE
	echo "Getting scheduler deployment to zero ... " && kubectl scale deployment --replicas 0 $SCHEDULER_DEPLOYMENT -n $NAMESPACE
}

function scale_up {
	echo "Getting workers deployment ... " && WORKER_DEPLOYMENT=$(kubectl get deploy -n $NAMESPACE | grep airflow-airflow-worker | awk '{print $1}')
	echo "Getting webserver deployment ... " && WEBSERVER_DEPLOYMENT=$(kubectl get deploy -n $NAMESPACE | grep airflow-airflow-webserver | awk '{print $1}')
	echo "Getting scheduler deployment ... " && SCHEDULER_DEPLOYMENT=$(kubectl get deploy -n $NAMESPACE | grep airflow-airflow-scheduler | awk '{print $1}')
	echo "Scaling worker deployment to zero ... " && kubectl scale deployment --replicas 20 $WORKER_DEPLOYMENT -n $NAMESPACE
	sleep 3
	echo "Scaling webserver deployment to one ... " && kubectl scale deployment --replicas 1 $WEBSERVER_DEPLOYMENT -n $NAMESPACE
	sleep 3
	echo "Scaling scheduler deployment to one ... " && kubectl scale deployment --replicas 1 $SCHEDULER_DEPLOYMENT -n $NAMESPACE
}

function install_dags {
  echo "get scheduler pod ..."
	SCHEDULER_POD=$(kubectl get pods -n $NAMESPACE | grep scheduler | awk '{print $1}')
  [ "${SCHEDULER_POD}" == "" ] && { echo "Unable to find the schduler pod, return from function ..."; exit 1; }

  echo "copying generate scripts and dag templates to scheduler pod ..."
	[ "${SCHEDULER_POD}" != "" ] \
	&& kubectl cp generate_test_dags_no_subdags.sh ${SCHEDULER_POD}:/tmp -n $NAMESPACE \
	&& kubectl cp template_dag_no_subdags.py ${SCHEDULER_POD}:/tmp -n $NAMESPACE

  echo "running generate dags script on scheduler pod ..."
	[ "${SCHEDULER_POD}" != "" ] && kubectl exec -it $SCHEDULER_POD -n $NAMESPACE -- bash -c /tmp/generate_test_dags_no_subdags.sh 
	sleep 3

  echo "listing dags ..."
	[ "${SCHEDULER_POD}" != "" ] && kubectl exec -it $SCHEDULER_POD -n $NAMESPACE -- bash -c \
	"airflow list_dags 2>&1 | egrep -iv 'DeprecationWarning|args:|args,|Passing though environment cleanly|ELASTICSEARCH'"
}


#===========================================================================================
# Main program
#===========================================================================================
read -n 1 -s -p "delete dags? [y/n]: " r
echo
[ "$r" == "y" ] && delete_dags

read -n 1 -s -p "scale to zero? [y/n]: " r
echo
[ "$r" == "y" ] && scale_to_zero

read -n 1 -s -p "make any config changes now.... press any key to continue..."
echo

read -n 1 -s -p "scale up? [y/n]: " r
echo
[ "$r" == "y" ] && scale_up

read -n 1 -s -p "install dags? [y/n]: " r
echo
[ "$r" == "y" ] && install_dags

# start logs 
# start outher monitors (and proxies)
