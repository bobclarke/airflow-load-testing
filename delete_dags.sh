for dag in $(cat /tmp/dags.txt); do echo "deleting dag $dag"; airflow delete_dag --yes $dag; done
