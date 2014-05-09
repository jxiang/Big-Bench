#!/usr/bin/env bash
#source "${BIG_BENCH_BASH_SCRIPT_DIR}/bigBenchEnvironment.sh"

CLUSTER_CONF=" -Dcore-site.xml=${BIG_BENCH_DATAGEN_CORE_SITE} -Dhdfs-site.xml=${BIG_BENCH_DATAGEN_HDFS_SITE} -Djava.library.path=${BIG_BENCH_HADOOP_LIBS_NATIVE} -DFileChannelProvider=pdgf.util.caching.fileWriter.HDFSChannelProvider -Ddfs.replication.override=${BIG_BENCH_DATAGEN_DFS_REPLICATION} "
echo $CLUSTER_CONF

if [ ! -f "${BIG_BENCH_NODES}" ]
then
	echo "Node file not found in ${BIG_BENCH_NODES}"
	exit 1
fi

IFS=$'\n' IPs=($(cat "${BIG_BENCH_NODES}"))
NODE_COUNT=${#IPs[@]}

# delete any previously generated data
echo "==============================================="
echo "Deleting any previously generated data."
echo "==============================================="
hadoop fs -rm -r -skipTrash "${BIG_BENCH_HDFS_ABSOLUTE_DATA_DIR}/*"

echo "==============================================="
echo "Starting data generation job."
echo "==============================================="
for (( i=0; i<${NODE_COUNT}; i++ ));
do
  echo ssh ${BIG_BENCH_SSH_OPTIONS} ${IPs[$i]} java ${BIG_BENCH_DATAGEN_JVM_ENV} ${CLUSTER_CONF} pdgf.Controller  -nc ${NODE_COUNT} -nn $((i+1)) -ns -c -o "${BIG_BENCH_DATAGEN_PDGF_OUT}" -s ${BIGBENCH_TABLES} $@
       ssh ${BIG_BENCH_SSH_OPTIONS} ${IPs[$i]} java ${BIG_BENCH_DATAGEN_JVM_ENV} ${CLUSTER_CONF} pdgf.Controller  -nc ${NODE_COUNT} -nn $((i+1)) -ns -c -o "${BIG_BENCH_DATAGEN_PDGF_OUT}" -s ${BIGBENCH_TABLES} $@ &
done
wait
echo "==============================================="
echo "Data generation job finished."
echo "Adding/Updating generated files to HIVE. (drops old tables)"
echo "==============================================="

${BIG_BENCH_HIVE_SCRIPT_DIR}/run.sh

echo "==============================================="
echo "Cluster job finished. Data is located in hdfs: ${BIG_BENCH_HDFS_ABSOLUTE_DATA_DIR}"
echo "View files: hadoop fs -ls ${BIG_BENCH_HDFS_ABSOLUTE_DATA_DIR}"
echo "HIVE load finished. You may start executing the queries"
echo "==============================================="