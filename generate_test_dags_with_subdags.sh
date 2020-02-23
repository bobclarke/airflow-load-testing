for dag in 1 2 3 4 5 6 7 8 9 
do sed s/TWITTERADS_PERF_TEST_SUBDAGS_00/TWITTERADS_PERF_TEST_SUBDAGS_${dag}/g template_dag_with_subdags.py > perf_subdags_${dag}.py 
done

for dag in a s d f g h j k l
do sed s/TWITTERADS_PERF_TEST_SUBDAGS_00/TWITTERADS_PERF_TEST_SUBDAGS_${dag}/g template_dag_with_subdags.py > perf_subdags_${dag}.py 
done

for dag in z x c v b n m 
do sed s/TWITTERADS_PERF_TEST_SUBDAGS_00/TWITTERADS_PERF_TEST_SUBDAGS_${dag}/g template_dag_with_subdags.py > perf_subdags_${dag}.py 
done

for dag in 11 22 33 44 55 66 77 88 99
do sed s/TWITTERADS_PERF_TEST_SUBDAGS_00/TWITTERADS_PERF_TEST_SUBDAGS_${dag}/g template_dag_with_subdags.py > perf_subdags_${dag}.py 
done

for dag in qq ww ee rr tt yy uu ii oo
do sed s/TWITTERADS_PERF_TEST_SUBDAGS_00/TWITTERADS_PERF_TEST_SUBDAGS_${dag}/g template_dag_with_subdags.py > perf_subdags_${dag}.py 
done
