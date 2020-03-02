for dag in 1 2 3 4 5 6 7 8 9 
do sed s/TWITTERADS_PERF_TEST_00/TWITTERADS_PERF_TEST_${dag}/g /tmp/template_dag_no_subdags.py > /usr/local/airflow/dags/perf_${dag}.py 
done
