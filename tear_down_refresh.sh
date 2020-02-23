#!/bin/sh

# Set up 
NAMESPACE="test"

# Functions 
function create_delete_dags_script {
	DAG_DELETE_SCRIPT='for dag in $(cat /tmp/dags.txt); do airflow delete_dag --yes $dag; done'
	echo $DAG_DELETE_SCRIPT > delete_dags.sh
	chmod +x delete_dags.sh
}

function delete_dags {
  echo "get scheduler pod ..."
	SCHEDULER_POD=$(kubectl get pods -n $NAMESPACE | grep scheduler | awk '{print $1}')
  [ "${SCHEDULER_POD}" == "" ] && { echo "Unable to find the schduler pod, return from function ..."; return 1; }
  echo "ssh to scheduler pod and list dags to file ..."
	[ "${SCHEDULER_POD}" != "" ] && kubectl exec -it $SCHEDULER_POD -n $NAMESPACE -- bash -c "airflow list_dags 2>&1 | grep PERF_TEST > /tmp/dags.txt"
  echo "ssh to scheduler pod and delete dag files from dags directory..."
	[ "${SCHEDULER_POD}" != "" ] && kubectl exec -it $SCHEDULER_POD -n $NAMESPACE -- bash -c "rm dags/*.py"
  echo "delete dags ..."
	[ "${SCHEDULER_POD}" != "" ] && kubectl cp delete_dags.sh ${SCHEDULER_POD}:/tmp -n $NAMESPACE && \
	kubectl exec -it $SCHEDULER_POD -n $NAMESPACE -- bash -c "/tmp/delete_dags.sh"
}

function scale_to_zero {
	echo "Getting workers deployment ... " && WORKER_DEPLOYMENT=$(kubectl get deploy -n $NAMESPACE | grep airflow-airflow-worker | awk '{print $1}')
	echo "Getting webserver deployment ... " && WEBSERVER_DEPLOYMENT=$(kubectl get deploy -n $NAMESPACE | grep airflow-airflow-webserver | awk '{print $1}')
	echo "Getting scheduler deployment ... " && SCHEDULER_DEPLOYMENT=$(kubectl get deploy -n $NAMESPACE | grep airflow-airflow-scheduler | awk '{print $1}')
	echo "Getting worker deployment to zero ... " && kubectl scale deployment --replicas 0 $WORKER_DEPLOYMENT -n $NAMESPACE
	# echo "Getting webserver deployment to zero ... " && kubectl scale deployment --replicas 0 $WEBSERVER_DEPLOYMENT -n $NAMESPACE
	echo "Getting scheduler deployment to zero ... " && kubectl scale deployment --replicas 0 $SCHEDULER_DEPLOYMENT -n $NAMESPACE
}

function scale_up {
	echo "Getting workers deployment ... " && WORKER_DEPLOYMENT=$(kubectl get deploy -n $NAMESPACE | grep airflow-airflow-worker | awk '{print $1}')
	echo "Getting webserver deployment ... " && WEBSERVER_DEPLOYMENT=$(kubectl get deploy -n $NAMESPACE | grep airflow-airflow-webserver | awk '{print $1}')
	echo "Getting scheduler deployment ... " && SCHEDULER_DEPLOYMENT=$(kubectl get deploy -n $NAMESPACE | grep airflow-airflow-scheduler | awk '{print $1}')
	echo "Scaling worker deployment to zero ... " && kubectl scale deployment --replicas 7 $WORKER_DEPLOYMENT -n $NAMESPACE
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
	[ "${SCHEDULER_POD}" != "" ] && kubectl cp generate_test_dags_no_subdags.sh ${SCHEDULER_POD}:/usr/local/airflow/dags -n $NAMESPACE \
	&& kubectl cp template_dag_no_subdags.py ${SCHEDULER_POD}:/usr/local/airflow/dags -n $NAMESPACE
  echo "running generate dags script on scheduler pod ..."
	kubectl exec -it ${SCHEDULER_POD} -n $NAMESPACE -- /usr/local/airflow/dags/generate_test_dags_no_subdags.sh 
	sleep 3
  echo "listing dags ..."
	kubectl exec -it ${SCHEDULER_POD} -n $NAMESPACE -- airflow list_dags 
}


# Main program
echo "create delete dags script? (y/n): " && read r
[ "$r" == "y" ] && create_delete_dags_script
echo "delete dags? (y/n): " && read r
[ "$r" == "y" ] && delete_dags
echo "scale to zero? (y/n): " && read r
[ "$r" == "y" ] && scale_to_zero
echo "scale up (y/n): " && read r
[ "$r" == "y" ] && scale_up
echo "install dags (y/n): " && read r
[ "$r" == "y" ] && install_dags




# work out scheduler and worker pod names 
# start logs 

# start outher monitors (and proxies)



